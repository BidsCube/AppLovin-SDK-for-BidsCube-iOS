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
    static let enableLogging = "enable_logging"
    static let enableLoggingCamel = "enableLogging"
    static let enableDebugMode = "enable_debug_mode"
    static let enableDebugModeCamel = "enableDebugMode"
    static let debug = "debug"
}

struct BidscubeMAXLoggingFlags: Equatable {
    let enableLogging: Bool
    let enableDebugMode: Bool
}

/// Resolves MAX server logging flags. Explicit server params override `isTesting` defaults.
func resolveBidscubeLoggingFlags(isTesting: Bool, serverParameters: [String: Any]) -> BidscubeMAXLoggingFlags {
    let enableLogging = readBooleanParameter(serverParameters, key: BidscubeMAXParams.enableLogging)
        ?? readBooleanParameter(serverParameters, key: BidscubeMAXParams.enableLoggingCamel)
        ?? isTesting
    let enableDebugMode = readBooleanParameter(serverParameters, key: BidscubeMAXParams.enableDebugMode)
        ?? readBooleanParameter(serverParameters, key: BidscubeMAXParams.enableDebugModeCamel)
        ?? readBooleanParameter(serverParameters, key: BidscubeMAXParams.debug)
        ?? isTesting
    return BidscubeMAXLoggingFlags(enableLogging: enableLogging, enableDebugMode: enableDebugMode)
}

private func applyBidscubeLogging(from parameters: MAAdapterParameters) {
    let flags = resolveBidscubeLoggingFlags(
        isTesting: parameters.isTesting,
        serverParameters: parameters.serverParameters
    )
    Logger.configureLogging(enableLogging: flags.enableLogging, enableDebugMode: flags.enableDebugMode)
    Logger.maxAdapterDebug(
        "logging=\(flags.enableLogging) debug=\(flags.enableDebugMode) isTesting=\(parameters.isTesting)"
    )
    if flags.enableDebugMode {
        Logger.deviceInfo()
    }
}

private func logBidscubeAdLoad(
    format: String,
    placementId: String,
    serverAppId: String?,
    parameters: MAAdapterParameters
) {
    let authority = URLBuilder.normalizedAdRequestAuthority(
        from: (parameters.serverParameters[BidscubeMAXParams.requestAuthority] as? String)
            ?? (parameters.serverParameters[BidscubeMAXParams.sspHost] as? String)
    )
    Logger.maxAdapter(
        "load \(format) placementId=\(placementId) serverAppId=\(serverAppId ?? "nil") authority=\(authority)"
    )
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

/// Resolves the Bidscube placement id for ad requests.
/// Matches Android `BidscubeMediationAdapter`: MAX **Placement ID** (`thirdPartyAdPlacementIdentifier`) is the
/// SSP placement (`id` / `placementId`). Server `app_id` is for SDK init only, not ad load URLs.
func resolveBidscubePlacementId(thirdPartyPlacementId: String?, serverAppId: String?) -> String {
    let placement = (thirdPartyPlacementId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if !placement.isEmpty {
        return placement
    }
    // Legacy fallback when MAX Placement ID is empty (do not prefer app_id — that is the init app id on Android).
    let legacyAppId = (serverAppId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    return legacyAppId
}

private func bidscubePlacementId(from parameters: MAAdapterResponseParameters) -> String {
    let serverAppId = parameters.serverParameters[BidscubeMAXParams.appId] as? String
    return resolveBidscubePlacementId(
        thirdPartyPlacementId: parameters.thirdPartyAdPlacementIdentifier,
        serverAppId: serverAppId
    )
}

private func bidscubeSDKConfig(from parameters: MAAdapterParameters) -> SDKConfig {
    let serverParameters = parameters.serverParameters
    let rawAuthority = (serverParameters[BidscubeMAXParams.requestAuthority] as? String)
        ?? (serverParameters[BidscubeMAXParams.sspHost] as? String)
    let loggingFlags = resolveBidscubeLoggingFlags(
        isTesting: parameters.isTesting,
        serverParameters: serverParameters
    )
    var builder = SDKConfig.Builder()
        .enableLogging(loggingFlags.enableLogging)
        .enableDebugMode(loggingFlags.enableDebugMode)
        .defaultAdTimeout(Constants.defaultTimeoutMs)
        .defaultAdPosition(.unknown)
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
    applyBidscubeLogging(from: parameters)
    applyUserIdIfNeeded(from: parameters)
    if BidscubeSDK.isInitialized() { return }
    BidscubeSDK.initialize(config: bidscubeSDKConfig(from: parameters))
    Logger.maxAdapter("SDK initialized")
}

private func runOnMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}

/// Holds the ad view reference for async callbacks (Android `adViewHolder[]` parity).
private final class BidscubeMAXAdViewHolder {
    var view: UIView?
}

/// Sizes the Bidscube view to the MAX ad slot (banner, MREC, leader).
private func applyMAXAdViewSlotConstraints(to view: UIView, size: CGSize) {
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        view.widthAnchor.constraint(equalToConstant: size.width),
        view.heightAnchor.constraint(equalToConstant: size.height)
    ])
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

        applyBidscubeLogging(from: parameters)
        BidscubeSDK.initialize(config: bidscubeSDKConfig(from: parameters))
        Logger.maxAdapter("initialize completed")
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
        let serverAppId = parameters.serverParameters[BidscubeMAXParams.appId] as? String
        logBidscubeAdLoad(
            format: adType.rawValue,
            placementId: placementId,
            serverAppId: serverAppId,
            parameters: parameters
        )
        guard BidscubeSDK.isInitialized() else {
            completion(nil, .notInitialized)
            return
        }
        guard !placementId.isEmpty else {
            completion(nil, mapLoadError("Missing Bidscube placement (MAX Placement ID)."))
            return
        }

        BidscubeSDK.loadAdPayload(placementId: placementId, adType: adType) { result in
            switch result {
            case .success(let payload):
                Logger.maxAdapter("load success placementId=\(placementId) adType=\(adType.rawValue)")
                completion(payload, nil)
            case .failure(let error):
                Logger.maxAdapter("load failed placementId=\(placementId) code=\(error.errorCode) message=\(error.message)")
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
    private var didTerminateDisplay = false

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
        guard !didTerminateDisplay else { return }
        didTerminateDisplay = true
        runOnMain {
            self.delegate?.didHideInterstitialAd()
        }
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        guard !didTerminateDisplay else { return }
        didTerminateDisplay = true
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
    private var didTerminateDisplay = false

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
        guard !didTerminateDisplay else { return }
        didTerminateDisplay = true
        runOnMain {
            self.maybeReward()
            self.delegate?.didHideRewardedAd()
        }
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        guard !didTerminateDisplay else { return }
        didTerminateDisplay = true
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

            guard BidscubeSDK.isInitialized() else {
                Logger.maxAdapter("loadAdViewAd: FAIL not initialized format=\(adFormat.label)")
                delegate.didFailToLoadAdViewAdWithError(.notInitialized)
                return
            }

            guard !placement.isEmpty else {
                Logger.maxAdapter("loadAdViewAd: FAIL missing placement format=\(adFormat.label)")
                delegate.didFailToLoadAdViewAdWithError(self.mapLoadError("Missing Bidscube placement (MAX Placement ID)."))
                return
            }

            let serverAppId = parameters.serverParameters[BidscubeMAXParams.appId] as? String
            logBidscubeAdLoad(
                format: adFormat.label,
                placementId: placement,
                serverAppId: serverAppId,
                parameters: parameters
            )

            if let presenter = parameters.presentingViewController ?? UIApplication.shared.alsc_topViewController() {
                BidscubeSDK.setDisplayViewController(presenter)
            }

            // Android parity: all MAX AdView formats use getImageAdView + adViewHolder callback wiring.
            let adViewHolder = BidscubeMAXAdViewHolder()
            let callback = BidscubeAdViewMAXCallback(delegate: delegate, adViewHolder: adViewHolder)
            adViewHolder.view = BidscubeSDK.getImageAdView(placement, callback)
            let view = adViewHolder.view!
            applyMAXAdViewSlotConstraints(to: view, size: adFormat.size)
            self.loadedBannerView = view
        }
    }
}

@available(iOS 13.0, *)
private final class BidscubeAdViewMAXCallback: NSObject, AdCallback {
    private weak var delegate: MAAdViewAdapterDelegate?
    private let adViewHolder: BidscubeMAXAdViewHolder

    init(delegate: MAAdViewAdapterDelegate, adViewHolder: BidscubeMAXAdViewHolder) {
        self.delegate = delegate
        self.adViewHolder = adViewHolder
        super.init()
    }

    func onAdLoading(_ placementId: String) {
        Logger.maxAdapter("adView loading placementId=\(placementId)")
    }

    func onAdLoaded(_ placementId: String) {
        guard let adView = adViewHolder.view else { return }
        Logger.maxAdapter("adView loaded placementId=\(placementId)")
        runOnMain {
            self.delegate?.didLoadAd(forAdView: adView)
        }
    }

    func onAdDisplayed(_ placementId: String) {
        Logger.maxAdapter("adView displayed placementId=\(placementId)")
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
        Logger.maxAdapter("adView failed placementId=\(placementId) code=\(errorCode) message=\(errorMessage)")
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
