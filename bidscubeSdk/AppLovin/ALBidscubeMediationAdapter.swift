import AppLovinSDK
import UIKit

// MARK: - Server parameter helpers

private enum BidscubeMAXParams {
    static let appId = "app_id"
    static let requestAuthority = "request_authority"
    static let sspHost = "ssp_host"
}

private func bidscubePlacementId(from parameters: MAAdapterResponseParameters) -> String {
    if let appId = parameters.serverParameters[BidscubeMAXParams.appId] as? String,
       !appId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return appId.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return parameters.thirdPartyAdPlacementIdentifier
}

private func bidscubeSDKConfig(fromServerParameters serverParameters: [String: Any]?) -> SDKConfig {
    let rawAuthority = (serverParameters?[BidscubeMAXParams.requestAuthority] as? String)
        ?? (serverParameters?[BidscubeMAXParams.sspHost] as? String)
    return SDKConfig.Builder()
        .enableLogging(false)
        .enableDebugMode(false)
        .defaultAdTimeout(Constants.defaultTimeoutMs)
        .defaultAdPosition(.fullScreen)
        .adRequestAuthority(rawAuthority)
        .enableSKAdNetwork(false)
        .build()
}

private func ensureBidscubeInitializedIfNeeded(from parameters: MAAdapterParameters) {
    if BidscubeSDK.isInitialized() { return }
    BidscubeSDK.initialize(config: bidscubeSDKConfig(fromServerParameters: parameters.serverParameters))
}

// MARK: - Native ad wrapper for MAX

private final class MABidscubeNativeAd: MANativeAd {
    override func prepare(forInteractionClickableViews clickableViews: [UIView], withContainer container: UIView) -> Bool {
        true
    }
}

// MARK: - Adapter

/// AppLovin MAX custom SDK adapter. Class name for MAX dashboard: `ALBidscubeMediationAdapter`.
@objc(ALBidscubeMediationAdapter)
@available(iOS 13.0, *)
final class ALBidscubeMediationAdapter: ALMediationAdapter {

    private static let initLock = NSLock()
    private static var didRunInitialization = false
    private static var lastInitStatus: MAAdapterInitializationStatus = .doesNotApply

    var interstitialPlacementId: String?
    var interstitialReady = false

    var rewardedPlacementId: String?
    var rewardedReady = false

    weak var loadedBannerView: UIView?
    weak var loadedNativeView: UIView?

    override var thirdPartySdkName: String { "Bidscube" }

    override var adapterVersion: String { "\(Constants.sdkVersion).0" }

    override var sdkVersion: String { Constants.sdkVersion }

    override func initialize(
        with parameters: MAAdapterInitializationParameters,
        completionHandler: @escaping MAAdapterInitializationCompletionHandler
    ) {
        Self.initLock.lock()
        defer { Self.initLock.unlock() }

        if Self.didRunInitialization {
            completionHandler(Self.lastInitStatus, nil)
            return
        }
        Self.didRunInitialization = true

        BidscubeSDK.initialize(config: bidscubeSDKConfig(fromServerParameters: parameters.serverParameters))
        Self.lastInitStatus = .initializedSuccess
        completionHandler(.initializedSuccess, nil)
    }

    override func destroy() {
        interstitialPlacementId = nil
        interstitialReady = false
        rewardedPlacementId = nil
        rewardedReady = false
        loadedBannerView = nil
        loadedNativeView = nil
    }

    private func mapLoadError(_ message: String) -> MAAdapterError {
        MAAdapterError(
            adapterError: .unspecified,
            mediatedNetworkErrorCode: MAAdapterError.errorCodeUnspecified,
            mediatedNetworkErrorMessage: message
        )
    }

    fileprivate func prefetchAd(
        placementId: String,
        adType: AdType,
        parameters: MAAdapterParameters,
        completion: @escaping (Bool, MAAdapterError?) -> Void
    ) {
        ensureBidscubeInitializedIfNeeded(from: parameters)
        guard BidscubeSDK.isInitialized() else {
            completion(false, .notInitialized)
            return
        }
        guard !placementId.isEmpty else {
            completion(false, mapLoadError("Missing Bidscube placement (MAX App ID / app_id)."))
            return
        }
        guard let url = BidscubeSDK.buildRequestURL(placementId: placementId, adType: adType) else {
            completion(false, mapLoadError(Constants.ErrorMessages.failedToBuildURL))
            return
        }
        NetworkManager.shared.get(url: url) { [weak self] result in
            switch result {
            case .success(let data):
                if data.isEmpty {
                    completion(false, .noFill)
                    return
                }
                if String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
                    completion(false, .noFill)
                    return
                }
                completion(true, nil)
            case .failure(let net):
                let adapter: MAAdapterError
                switch net {
                case .timeout:
                    adapter = .timeout
                case .networkUnavailable:
                    adapter = .noConnection
                default:
                    adapter = self?.mapLoadError(net.localizedDescription) ?? .unspecified
                }
                completion(false, adapter)
            }
        }
    }
}

// MARK: - Interstitial

@available(iOS 13.0, *)
extension ALBidscubeMediationAdapter: MAInterstitialAdapter {

    func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        let placement = bidscubePlacementId(from: parameters)
        ensureBidscubeInitializedIfNeeded(from: parameters)
        interstitialReady = false
        interstitialPlacementId = nil

        prefetchAd(placementId: placement, adType: .image, parameters: parameters) { [weak adapterRef = self] ok, err in
            DispatchQueue.main.async {
                guard let adapter = adapterRef else { return }
                if ok {
                    adapter.interstitialPlacementId = placement
                    adapter.interstitialReady = true
                    delegate.didLoadInterstitialAd()
                } else if let err {
                    delegate.didFailToLoadInterstitialAdWithError(err)
                }
            }
        }
    }

    func showInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        let placement = bidscubePlacementId(from: parameters)
        guard interstitialReady, interstitialPlacementId == placement,
              let presenter = parameters.presentingViewController ?? UIApplication.shared.alsc_topViewController() else {
            let err = MAAdapterError(
                adapterError: MAAdapterError.adDisplayFailedError,
                mediatedNetworkErrorCode: MAAdapterError.adNotReady.code.rawValue,
                mediatedNetworkErrorMessage: MAAdapterError.adNotReady.message
            )
            delegate.didFailToDisplayInterstitialAdWithError(err)
            return
        }

        let callback = BidscubeInterstitialMAXCallback(delegate: delegate)
        BidscubeSDK.presentImageAd(placement, from: presenter, callback: callback)
        interstitialReady = false
        interstitialPlacementId = nil
    }
}

@available(iOS 13.0, *)
private final class BidscubeInterstitialMAXCallback: NSObject, AdCallback {
    private weak var delegate: MAInterstitialAdapterDelegate?

    init(delegate: MAInterstitialAdapterDelegate) {
        self.delegate = delegate
        super.init()
    }

    func onAdLoading(_ placementId: String) {}

    func onAdLoaded(_ placementId: String) {}

    func onAdDisplayed(_ placementId: String) {
        delegate?.didDisplayInterstitialAd()
    }

    func onAdClicked(_ placementId: String) {
        delegate?.didClickInterstitialAd()
    }

    func onAdClosed(_ placementId: String) {
        delegate?.didHideInterstitialAd()
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        let err = MAAdapterError(
            adapterError: MAAdapterError.adDisplayFailedError,
            mediatedNetworkErrorCode: errorCode,
            mediatedNetworkErrorMessage: errorMessage
        )
        delegate?.didFailToDisplayInterstitialAdWithError(err)
    }
}

// MARK: - Rewarded

@available(iOS 13.0, *)
extension ALBidscubeMediationAdapter: MARewardedAdapter {

    func loadRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        let placement = bidscubePlacementId(from: parameters)
        ensureBidscubeInitializedIfNeeded(from: parameters)
        rewardedReady = false
        rewardedPlacementId = nil

        prefetchAd(placementId: placement, adType: .video, parameters: parameters) { [weak adapterRef = self] ok, err in
            DispatchQueue.main.async {
                guard let adapter = adapterRef else { return }
                if ok {
                    adapter.rewardedPlacementId = placement
                    adapter.rewardedReady = true
                    delegate.didLoadRewardedAd()
                } else if let err {
                    delegate.didFailToLoadRewardedAdWithError(err)
                }
            }
        }
    }

    func showRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        let placement = bidscubePlacementId(from: parameters)
        guard rewardedReady, rewardedPlacementId == placement,
              let presenter = parameters.presentingViewController ?? UIApplication.shared.alsc_topViewController() else {
            let err = MAAdapterError(
                adapterError: MAAdapterError.adDisplayFailedError,
                mediatedNetworkErrorCode: MAAdapterError.adNotReady.code.rawValue,
                mediatedNetworkErrorMessage: MAAdapterError.adNotReady.message
            )
            delegate.didFailToDisplayRewardedAdWithError(err)
            return
        }

        configureReward(for: parameters)
        let callback = BidscubeRewardedMAXCallback(adapter: self, delegate: delegate)
        BidscubeSDK.presentVideoAd(placement, from: presenter, callback: callback)
        rewardedReady = false
        rewardedPlacementId = nil
    }
}

@available(iOS 13.0, *)
private final class BidscubeRewardedMAXCallback: NSObject, AdCallback {
    private weak var adapter: ALBidscubeMediationAdapter?
    private weak var delegate: MARewardedAdapterDelegate?
    private var granted = false

    init(adapter: ALBidscubeMediationAdapter, delegate: MARewardedAdapterDelegate) {
        self.adapter = adapter
        self.delegate = delegate
        super.init()
    }

    func onAdLoading(_ placementId: String) {}

    func onAdLoaded(_ placementId: String) {}

    func onAdDisplayed(_ placementId: String) {
        delegate?.didDisplayRewardedAd()
    }

    func onAdClicked(_ placementId: String) {
        delegate?.didClickRewardedAd()
    }

    func onAdClosed(_ placementId: String) {
        if granted || adapter?.shouldAlwaysRewardUser == true, let reward = adapter?.reward {
            delegate?.didRewardUser(with: reward)
        }
        delegate?.didHideRewardedAd()
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        let err = MAAdapterError(
            adapterError: MAAdapterError.adDisplayFailedError,
            mediatedNetworkErrorCode: errorCode,
            mediatedNetworkErrorMessage: errorMessage
        )
        delegate?.didFailToDisplayRewardedAdWithError(err)
    }

    func onVideoAdCompleted(_ placementId: String) {
        granted = true
    }
}

// MARK: - Banner / MREC / Leader

@available(iOS 13.0, *)
extension ALBidscubeMediationAdapter: MAAdViewAdapter {

    func loadAdViewAd(
        for parameters: MAAdapterResponseParameters,
        adFormat: MAAdFormat,
        andNotify delegate: MAAdViewAdapterDelegate
    ) {
        let placement = bidscubePlacementId(from: parameters)
        ensureBidscubeInitializedIfNeeded(from: parameters)

        guard !placement.isEmpty else {
            delegate.didFailToLoadAdViewAdWithError(mapLoadError("Missing Bidscube placement (MAX App ID / app_id)."))
            return
        }

        let size = adFormat.size
        let callback = BidscubeAdViewMAXCallback(delegate: delegate, adView: nil)
        let view: UIView

        if adFormat.isBannerOrLeaderAd {
            let isLeader = adFormat.label.uppercased().contains("LEADER")
            let position: AdPosition = isLeader ? .sidebar : .footer
            let banner = BidscubeSDK.getBannerAdView(placement, position: position, callback: callback)
            banner.setBannerDimensions(width: size.width, height: size.height)
            view = banner
        } else {
            view = BidscubeSDK.getImageAdView(placement, callback)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: size.width),
                view.heightAnchor.constraint(equalToConstant: size.height)
            ])
        }

        callback.adView = view
        loadedBannerView = view
    }
}

@available(iOS 13.0, *)
private final class BidscubeAdViewMAXCallback: NSObject, AdCallback {
    private weak var delegate: MAAdViewAdapterDelegate?
    weak var adView: UIView?

    init(delegate: MAAdViewAdapterDelegate, adView: UIView?) {
        self.delegate = delegate
        self.adView = adView
        super.init()
    }

    func onAdLoading(_ placementId: String) {}

    func onAdLoaded(_ placementId: String) {
        guard let adView else { return }
        delegate?.didLoadAd(forAdView: adView)
    }

    func onAdDisplayed(_ placementId: String) {
        delegate?.didDisplayAdViewAd()
    }

    func onAdClicked(_ placementId: String) {
        delegate?.didClickAdViewAd()
    }

    func onAdClosed(_ placementId: String) {
        delegate?.didHideAdViewAd()
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        let err = MAAdapterError(
            adapterError: .unspecified,
            mediatedNetworkErrorCode: errorCode,
            mediatedNetworkErrorMessage: errorMessage
        )
        delegate?.didFailToLoadAdViewAdWithError(err)
    }
}

// MARK: - Native (MANativeAdAdapter)

@available(iOS 13.0, *)
extension ALBidscubeMediationAdapter: MANativeAdAdapter {

    func loadNativeAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MANativeAdAdapterDelegate) {
        let placement = bidscubePlacementId(from: parameters)
        ensureBidscubeInitializedIfNeeded(from: parameters)

        guard !placement.isEmpty else {
            delegate.didFailToLoadNativeAdWithError(MAAdapterError(
                adapterError: .unspecified,
                mediatedNetworkErrorCode: MAAdapterError.errorCodeUnspecified,
                mediatedNetworkErrorMessage: "Missing Bidscube placement (MAX App ID / app_id)."
            ))
            return
        }

        let screenW = Int(UIScreen.main.bounds.width)
        let screenH = Int(UIScreen.main.bounds.height)
        let callback = BidscubeNativeMAXCallback(adapter: self, delegate: delegate)
        let view = BidscubeSDK.getNativeAdView(placement, width: screenW, height: screenH, callback)
        loadedNativeView = view
    }
}

@available(iOS 13.0, *)
private final class BidscubeNativeMAXCallback: NSObject, AdCallback {
    private weak var adapter: ALBidscubeMediationAdapter?
    private weak var delegate: MANativeAdAdapterDelegate?

    init(adapter: ALBidscubeMediationAdapter, delegate: MANativeAdAdapterDelegate) {
        self.adapter = adapter
        self.delegate = delegate
        super.init()
    }

    func onAdLoading(_ placementId: String) {}

    func onAdLoaded(_ placementId: String) {
        guard let adapter, let media = adapter.loadedNativeView else {
            delegate?.didFailToLoadNativeAdWithError(.invalidConfiguration)
            return
        }
        let nativeAd = MABidscubeNativeAd(format: MAAdFormat.native) { builder in
            builder.mediaView = media
        }
        delegate?.didLoadAd(for: nativeAd, withExtraInfo: nil)
    }

    func onAdDisplayed(_ placementId: String) {
        delegate?.didDisplayNativeAd(withExtraInfo: nil)
    }

    func onAdClicked(_ placementId: String) {
        delegate?.didClickNativeAd()
    }

    func onAdClosed(_ placementId: String) {}

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        let err = MAAdapterError(
            adapterError: .unspecified,
            mediatedNetworkErrorCode: errorCode,
            mediatedNetworkErrorMessage: errorMessage
        )
        delegate?.didFailToLoadNativeAdWithError(err)
    }
}

// MARK: - UIApplication key window helper

private extension UIApplication {
    func alsc_topViewController() -> UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        if let nav = top as? UINavigationController {
            return nav.visibleViewController
        }
        if let tab = top as? UITabBarController {
            return tab.selectedViewController
        }
        return top
    }
}
