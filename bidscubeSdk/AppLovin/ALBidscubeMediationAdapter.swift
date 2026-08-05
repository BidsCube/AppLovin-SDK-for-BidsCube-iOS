import AppLovinSDK
import UIKit

// MARK: - Server parameter helpers

private enum BidscubeMAXParams {
    static let appId = "app_id"
    static let requestAuthority = "request_authority"
    static let sspHost = "ssp_host"
    static let userId = "user_id"
    static let userIdCamel = "userId"
    static let autoClose = "auto_close"
    static let autoCloseCamel = "autoClose"
}

private func readBooleanParameter(_ serverParameters: [String: Any], key: String) -> Bool? {
    guard let raw = serverParameters[key] else { return nil }
    if let value = raw as? Bool { return value }
    guard let text = raw as? String else { return nil }
    let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if ["true", "1", "yes"].contains(normalized) { return true }
    if ["false", "0", "no"].contains(normalized) { return false }
    return nil
}

private func bidscubeAutoClose(from serverParameters: [String: Any]) -> Bool {
    if let value = readBooleanParameter(serverParameters, key: BidscubeMAXParams.autoClose) { return value }
    if let value = readBooleanParameter(serverParameters, key: BidscubeMAXParams.autoCloseCamel) { return value }
    return false
}

private func bidscubeUserId(from serverParameters: [String: Any]) -> String? {
    if let userId = serverParameters[BidscubeMAXParams.userId] as? String,
       let normalized = SDKConfig.normalizeUserId(userId) {
        return normalized
    }
    if let userId = serverParameters[BidscubeMAXParams.userIdCamel] as? String,
       let normalized = SDKConfig.normalizeUserId(userId) {
        return normalized
    }
    return nil
}

private func bidscubePlacementId(from parameters: MAAdapterResponseParameters) -> String {
    if let appId = parameters.serverParameters[BidscubeMAXParams.appId] as? String,
       !appId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return appId.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return parameters.thirdPartyAdPlacementIdentifier
}

private func bidscubeSDKConfig(from parameters: MAAdapterParameters) -> SDKConfig {
    let serverParameters = parameters.serverParameters
    let rawAuthority = (serverParameters[BidscubeMAXParams.requestAuthority] as? String)
        ?? (serverParameters[BidscubeMAXParams.sspHost] as? String)
    let isTesting = parameters.isTesting
    var builder = SDKConfig.Builder()
        .enableLogging(isTesting)
        .enableDebugMode(isTesting)
        .defaultAdTimeout(Constants.defaultTimeoutMs)
        .defaultAdPosition(.fullScreen)
        .adRequestAuthority(rawAuthority)
        .enableSKAdNetwork(false)
    if let userId = bidscubeUserId(from: serverParameters) {
        builder = builder.userId(userId)
    }
    builder = builder.autoClose(bidscubeAutoClose(from: serverParameters))
    return builder.build()
}

private func applyUserIdIfNeeded(from parameters: MAAdapterParameters) {
    guard let userId = bidscubeUserId(from: parameters.serverParameters) else { return }
    if BidscubeSDK.isInitialized() {
        BidscubeSDK.setUserId(userId)
    }
}

private func ensureBidscubeInitializedIfNeeded(from parameters: MAAdapterParameters) {
    applyUserIdIfNeeded(from: parameters)
    if BidscubeSDK.isInitialized() { return }
    BidscubeSDK.initialize(config: bidscubeSDKConfig(from: parameters))
}

private func runOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
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
    var cachedInterstitialPayload: BidscubeSDK.BidscubeAdPayload?

    var rewardedPlacementId: String?
    var rewardedReady = false
    var cachedRewardedPayload: BidscubeSDK.BidscubeAdPayload?

    weak var loadedBannerView: UIView?

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

        BidscubeSDK.initialize(config: bidscubeSDKConfig(from: parameters))
        Self.lastInitStatus = .initializedSuccess
        completionHandler(.initializedSuccess, nil)
    }

    override func destroy() {
        interstitialPlacementId = nil
        interstitialReady = false
        cachedInterstitialPayload = nil
        rewardedPlacementId = nil
        rewardedReady = false
        cachedRewardedPayload = nil
        loadedBannerView = nil
    }

    private func mapLoadError(_ message: String) -> MAAdapterError {
        MAAdapterError(
            adapterError: .unspecified,
            mediatedNetworkErrorCode: MAAdapterError.errorCodeUnspecified,
            mediatedNetworkErrorMessage: message
        )
    }

    private func mapRequestError(_ error: BidscubeRequestError) -> MAAdapterError {
        switch error.errorCode {
        case AdErrorCode.noFill:
            return .noFill
        case AdErrorCode.networkError where error.message.localizedCaseInsensitiveContains("timed out"):
            return .timeout
        case AdErrorCode.networkError:
            return .noConnection
        default:
            return MAAdapterError(
                adapterError: .unspecified,
                mediatedNetworkErrorCode: error.errorCode,
                mediatedNetworkErrorMessage: error.message
            )
        }
    }

    fileprivate func loadAndCachePayload(
        placementId: String,
        adType: AdType,
        parameters: MAAdapterParameters,
        completion: @escaping (BidscubeSDK.BidscubeAdPayload?, MAAdapterError?) -> Void
    ) {
        ensureBidscubeInitializedIfNeeded(from: parameters)
        guard BidscubeSDK.isInitialized() else {
            completion(nil, .notInitialized)
            return
        }
        guard !placementId.isEmpty else {
            completion(nil, mapLoadError("Missing Bidscube placement (MAX App ID / app_id)."))
            return
        }

        BidscubeSDK.loadAdPayload(placementId: placementId, adType: adType) { result in
            switch result {
            case .success(let payload):
                completion(payload, nil)
            case .failure(let error):
                completion(nil, self.mapRequestError(error))
            }
        }
    }
}

// MARK: - Signal collection

@available(iOS 13.0, *)
extension ALBidscubeMediationAdapter: MASignalProvider {

    func collectSignal(with parameters: MASignalCollectionParameters, andNotify delegate: MASignalCollectionDelegate) {
        let signal = BidscubeSDK.collectSignal(adapterVersion: adapterVersion)
        delegate.didCollectSignal(signal)
    }
}

// MARK: - Interstitial (video)

@available(iOS 13.0, *)
extension ALBidscubeMediationAdapter: MAInterstitialAdapter {

    func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        let placement = bidscubePlacementId(from: parameters)
        ensureBidscubeInitializedIfNeeded(from: parameters)
        interstitialReady = false
        interstitialPlacementId = nil
        cachedInterstitialPayload = nil

        loadAndCachePayload(placementId: placement, adType: .video, parameters: parameters) { [weak self] payload, err in
            runOnMain {
                guard let self else { return }
                if let payload {
                    self.cachedInterstitialPayload = payload
                    self.interstitialPlacementId = placement
                    self.interstitialReady = true
                    delegate.didLoadInterstitialAd()
                } else if let err {
                    delegate.didFailToLoadInterstitialAdWithError(err)
                }
            }
        }
    }

    func showInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        let placement = bidscubePlacementId(from: parameters)
        guard interstitialReady,
              interstitialPlacementId == placement,
              let payload = cachedInterstitialPayload,
              let presenter = parameters.presentingViewController ?? UIApplication.shared.alsc_topViewController() else {
            let err = MAAdapterError(
                adapterError: MAAdapterError.adDisplayFailedError,
                mediatedNetworkErrorCode: MAAdapterError.adNotReady.code.rawValue,
                mediatedNetworkErrorMessage: MAAdapterError.adNotReady.message
            )
            runOnMain {
                delegate.didFailToDisplayInterstitialAdWithError(err)
            }
            return
        }

        runOnMain {
            BidscubeSDK.setDisplayViewController(presenter)
            let callback = BidscubeInterstitialMAXCallback(delegate: delegate)
            BidscubeSDK.presentCachedAd(payload, from: presenter, callback: callback)
            self.interstitialReady = false
            self.interstitialPlacementId = nil
            self.cachedInterstitialPayload = nil
        }
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
        runOnMain {
            self.delegate?.didDisplayInterstitialAd()
        }
    }

    func onAdClicked(_ placementId: String) {
        runOnMain {
            self.delegate?.didClickInterstitialAd()
        }
    }

    func onAdClosed(_ placementId: String) {
        runOnMain {
            self.delegate?.didHideInterstitialAd()
        }
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        let err = MAAdapterError(
            adapterError: MAAdapterError.adDisplayFailedError,
            mediatedNetworkErrorCode: errorCode,
            mediatedNetworkErrorMessage: errorMessage
        )
        runOnMain {
            self.delegate?.didFailToDisplayInterstitialAdWithError(err)
        }
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
        cachedRewardedPayload = nil

        loadAndCachePayload(placementId: placement, adType: .video, parameters: parameters) { [weak self] payload, err in
            runOnMain {
                guard let self else { return }
                if let payload {
                    self.cachedRewardedPayload = payload
                    self.rewardedPlacementId = placement
                    self.rewardedReady = true
                    delegate.didLoadRewardedAd()
                } else if let err {
                    delegate.didFailToLoadRewardedAdWithError(err)
                }
            }
        }
    }

    func showRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        let placement = bidscubePlacementId(from: parameters)
        guard rewardedReady,
              rewardedPlacementId == placement,
              let payload = cachedRewardedPayload,
              let presenter = parameters.presentingViewController ?? UIApplication.shared.alsc_topViewController() else {
            let err = MAAdapterError(
                adapterError: MAAdapterError.adDisplayFailedError,
                mediatedNetworkErrorCode: MAAdapterError.adNotReady.code.rawValue,
                mediatedNetworkErrorMessage: MAAdapterError.adNotReady.message
            )
            runOnMain {
                delegate.didFailToDisplayRewardedAdWithError(err)
            }
            return
        }

        configureReward(for: parameters)
        runOnMain {
            BidscubeSDK.setDisplayViewController(presenter)
            let callback = BidscubeRewardedMAXCallback(adapter: self, delegate: delegate)
            BidscubeSDK.presentCachedAd(payload, from: presenter, callback: callback)
            self.rewardedReady = false
            self.rewardedPlacementId = nil
            self.cachedRewardedPayload = nil
        }
    }
}

@available(iOS 13.0, *)
private final class BidscubeRewardedMAXCallback: NSObject, AdCallback {
    private weak var adapter: ALBidscubeMediationAdapter?
    private weak var delegate: MARewardedAdapterDelegate?
    private var videoCompleted = false
    private var didReward = false

    init(adapter: ALBidscubeMediationAdapter, delegate: MARewardedAdapterDelegate) {
        self.adapter = adapter
        self.delegate = delegate
        super.init()
    }

    func onAdLoading(_ placementId: String) {}

    func onAdLoaded(_ placementId: String) {}

    func onAdDisplayed(_ placementId: String) {
        runOnMain {
            self.delegate?.didDisplayRewardedAd()
        }
    }

    func onAdClicked(_ placementId: String) {
        runOnMain {
            self.delegate?.didClickRewardedAd()
        }
    }

    func onAdClosed(_ placementId: String) {
        runOnMain {
            self.maybeReward()
            self.delegate?.didHideRewardedAd()
        }
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        let err = MAAdapterError(
            adapterError: MAAdapterError.adDisplayFailedError,
            mediatedNetworkErrorCode: errorCode,
            mediatedNetworkErrorMessage: errorMessage
        )
        runOnMain {
            self.delegate?.didFailToDisplayRewardedAdWithError(err)
        }
    }

    func onVideoAdCompleted(_ placementId: String) {
        videoCompleted = true
    }

    func onVideoAdSkipped(_ placementId: String) {
        videoCompleted = false
    }

    private func maybeReward() {
        guard !didReward else { return }
        guard videoCompleted || adapter?.shouldAlwaysRewardUser == true else { return }
        guard let reward = adapter?.reward else { return }

        didReward = true
        delegate?.didRewardUser(with: reward)
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

        runOnMain { [weak self] in
            guard let self else { return }
            ensureBidscubeInitializedIfNeeded(from: parameters)

            guard !placement.isEmpty else {
                delegate.didFailToLoadAdViewAdWithError(self.mapLoadError("Missing Bidscube placement (MAX App ID / app_id)."))
                return
            }

            if let presenter = parameters.presentingViewController ?? UIApplication.shared.alsc_topViewController() {
                BidscubeSDK.setDisplayViewController(presenter)
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
            self.loadedBannerView = view
        }
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
        runOnMain {
            self.delegate?.didLoadAd(forAdView: adView)
        }
    }

    func onAdDisplayed(_ placementId: String) {
        runOnMain {
            self.delegate?.didDisplayAdViewAd()
        }
    }

    func onAdClicked(_ placementId: String) {
        runOnMain {
            self.delegate?.didClickAdViewAd()
        }
    }

    func onAdClosed(_ placementId: String) {
        runOnMain {
            self.delegate?.didHideAdViewAd()
        }
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        let err = MAAdapterError(
            adapterError: .unspecified,
            mediatedNetworkErrorCode: errorCode,
            mediatedNetworkErrorMessage: errorMessage
        )
        runOnMain {
            self.delegate?.didFailToLoadAdViewAdWithError(err)
        }
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
