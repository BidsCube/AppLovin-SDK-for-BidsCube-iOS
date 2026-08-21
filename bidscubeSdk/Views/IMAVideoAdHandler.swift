import UIKit
import SwiftUI
import AVFoundation
import GoogleInteractiveMediaAds

public final class IMAVideoAdHandler: UIView {
    
    private var contentPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var adsLoader: IMAAdsLoader?
    private var adsManager: IMAAdsManager?
    private var adDisplayContainer: IMAAdDisplayContainer?
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    
    private var vastURL: String?
    private var vastXML: String?
    private var clickURL: String?
    private var placementId: String = ""
    private weak var callback: AdCallback?
    private weak var parentViewController: UIViewController?
    
    private var navigationChrome: FullscreenVideoChromeControls?
    private var sessionController: FullscreenVideoSessionController?
    private var postVideoCompanion: CompanionAd?
    private var staticEndCard: CompanionEndCardView?
    private var htmlEndCard: CompanionEndCardView?
    private var skipOverlay: VideoSkipControlOverlay?
    private var didDismissUI = false
    private let handlerInstanceId = UUID()
    private weak var boundViewController: UIViewController?
    private var isPlaybackActive = false
    private var hasRequestedAds = false
    private var activeContainerId: String?
    private var containerCreatedCount = 0
    private var requestAdsCount = 0
    
    public init(vastURL: String, clickURL: String? = nil) {
        self.vastURL = vastURL
        self.vastXML = nil
        self.clickURL = clickURL
        super.init(frame: .zero)
        setupBasicView()
    }
    
    public init(vastXML: String, clickURL: String? = nil) {
        self.vastURL = nil
        self.vastXML = vastXML
        self.clickURL = clickURL
        super.init(frame: .zero)
        setupBasicView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setPlacementInfo(_ placementId: String, callback: AdCallback?) {
        self.placementId = placementId
        self.callback = callback
    }
    
    public func setParentViewController(_ viewController: UIViewController?) {
        self.parentViewController = viewController
    }
    
    public func refreshIMASetup() {
        rebindViewControllerIfNeeded()
    }

    /// Idempotent hierarchy rebind — never replaces container after `requestAds`.
    func rebindViewControllerIfNeeded() {
        if hasRequestedAds || isPlaybackActive || adsManager != nil {
            playerLayer?.frame = bounds
            logDiagnostics("rebind blocked hasRequestedAds=\(hasRequestedAds) playback=\(isPlaybackActive) manager=\(adsManager != nil)")
            return
        }

        if adDisplayContainer != nil, boundViewController != nil {
            playerLayer?.frame = bounds
            return
        }

        guard let viewController = findStableViewController() else {
            logDiagnostics("rebind failed: no stable presenter")
            return
        }

        createAdDisplayContainer(boundTo: viewController)
    }

    private func createAdDisplayContainer(boundTo viewController: UIViewController) {
        guard adDisplayContainer == nil else {
            playerLayer?.frame = bounds
            logDiagnostics("ensureAdDisplayContainer skipped existing")
            return
        }
        boundViewController = viewController
        adDisplayContainer = IMAAdDisplayContainer(adContainer: self, viewController: viewController)
        activeContainerId = FullscreenLifecycleDiagnostics.objectID(adDisplayContainer)
        containerCreatedCount += 1
        logDiagnostics("containerCreated count=\(containerCreatedCount) vc=\(type(of: viewController))")
    }

    @discardableResult
    private func ensurePlayer() -> Bool {
        if contentPlayer != nil {
            playerLayer?.frame = bounds
            return true
        }
        contentPlayer = AVPlayer()
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer!)
        playerLayer = AVPlayerLayer(player: contentPlayer)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = bounds
        if let layer = playerLayer {
            self.layer.addSublayer(layer)
        }
        return true
    }

    @discardableResult
    private func ensureAdDisplayContainer() -> Bool {
        if adDisplayContainer != nil {
            return true
        }
        if hasRequestedAds {
            logDiagnostics("lifecycle_violation container_create_after_requestAds")
            return false
        }
        guard let viewController = findStableViewController() else {
            logDiagnostics(
                "ima_presenter_unavailable viewInWindow=\(window != nil) parentAttached=\(parentViewController?.view.window != nil)"
            )
            return false
        }
        createAdDisplayContainer(boundTo: viewController)
        return adDisplayContainer != nil
    }

    @discardableResult
    private func ensureAdsLoader() -> Bool {
        if adsLoader != nil {
            return true
        }
        Logger.player("Initializing default IMA player for placement \(placementId)")
        let settings = IMASettings()
        settings.enableDebugMode = true
        settings.maxRedirects = 5
        settings.autoPlayAdBreaks = true
        settings.language = "en"
        adsLoader = IMAAdsLoader(settings: settings)
        adsLoader?.delegate = self
        return adsLoader != nil
    }

    private func logDiagnostics(_ message: String) {
        let containerField = "display_container_id=\(activeContainerId ?? "nil")"
        FullscreenLifecycleDiagnostics.log(
            "IMA",
            "\(containerField) \(message)",
            placementId: placementId,
            handler: self,
            controller: boundViewController
        )
    }

    private func dispatchOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
    
    public func cleanup() {
        logDiagnostics("cleanup_before_clear")
        isPlaybackActive = false
        hasRequestedAds = false
        destroySkipOverlay()
        staticEndCard?.destroy()
        staticEndCard = nil
        htmlEndCard?.destroy()
        htmlEndCard = nil

        adsManager?.delegate = nil
        adsManager?.destroy()
        adsManager = nil

        adsLoader?.delegate = nil
        adsLoader = nil

        adDisplayContainer = nil
        activeContainerId = nil
        boundViewController = nil
        logDiagnostics("cleanup_after_clear")

        contentPlayhead = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        contentPlayer = nil

        gestureRecognizers?.forEach { removeGestureRecognizer($0) }
        backgroundColor = .clear
    }
    
    deinit {
        cleanup()
    }
    
    public func loadAd() {
        guard !hasRequestedAds else {
            logDiagnostics("lifecycle_violation_duplicate_requestAds")
            return
        }

        ensureSessionController()
        Logger.player("Setting up IMA player before loading ad for placement \(placementId)")
        setupIMA()

        guard let adsLoader = adsLoader else {
            print("Error: IMAVideoAdHandler: AdsLoader not initialized")
            return
        }

        guard let adDisplayContainer = adDisplayContainer else {
            print("Error: IMAVideoAdHandler: AdDisplayContainer not initialized")
            return
        }

        hasRequestedAds = true
        requestAdsCount += 1
        logDiagnostics("requestAds started count=\(requestAdsCount)")
        
        if let vastURL = vastURL {
            let adsRequest = IMAAdsRequest(
                adTagUrl: vastURL,
                adDisplayContainer: adDisplayContainer,
                contentPlayhead: contentPlayhead,
                userContext: nil
            )
            
            adsLoader.requestAds(with: adsRequest)
        }
        else if let vastXML = vastXML {
            let dataURI = "data:application/xml;base64,\(Data(vastXML.utf8).base64EncodedString())"
            
            let adsRequest = IMAAdsRequest(
                adTagUrl: dataURI,
                adDisplayContainer: adDisplayContainer,
                contentPlayhead: contentPlayhead,
                userContext: nil
            )
            
            adsLoader.requestAds(with: adsRequest)
        } else {
            print("Error: IMAVideoAdHandler: No VAST URL or XML content provided")
            callback?.onAdFailed(placementId, errorCode: -1, errorMessage: "No VAST content provided")
        }
    }
    
    private func setupBasicView() {
        backgroundColor = .black
        isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAdClick))
        addGestureRecognizer(tapGesture)
        
        setupNavigationChrome()

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeGesture.direction = .right
        addGestureRecognizer(swipeGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }
    
    private func setupNavigationChrome() {
        let chrome = FullscreenVideoChromeControls(
            target: self,
            backAction: #selector(closeButtonTapped),
            closeAction: #selector(closeButtonTapped)
        )
        chrome.install(in: self)
        navigationChrome = chrome
    }
    
    private func setupIMA() {
        _ = ensurePlayer()
        _ = ensureAdDisplayContainer()
        _ = ensureAdsLoader()
    }

    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    @objc private func handleAdClick() {
        print("🔍 IMAVideoAdHandler: Ad clicked for placement: \(placementId)")
        
        callback?.onAdClicked(placementId)
        
        if let clickURL = clickURL, let url = URL(string: clickURL) {
            print("🔍 IMAVideoAdHandler: Opening URL in browser: \(clickURL)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("⚠️ IMAVideoAdHandler: No click URL available")
        }
    }
    
    @objc private func closeButtonTapped() {
        requestUserClose()
    }
    
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        requestUserClose()
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        requestUserClose()
    }

    private func ensureSessionController() {
        if sessionController != nil { return }
        sessionController = FullscreenVideoSessionController(
            autoClose: BidscubeSDK.isAutoClose(),
            playerManagesPostVideo: true,
            vastXml: vastXML
        )
        if let vastXML {
            postVideoCompanion = VastParser.selectPostVideoCompanion(vastXML)
        }
    }

    private func requestUserClose() {
        ensureSessionController()
        let action = sessionController?.onUserClose() ?? {
            var fallback = FullscreenPostVideoAction()
            fallback.fireAdClosed = true
            fallback.releasePlayer = true
            fallback.hidePlayer = true
            fallback.dismissDialog = true
            return fallback
        }()
        applyPostVideoAction(action, trigger: "USER_CLOSE")
    }

    private func applyPostVideoAction(_ action: FullscreenPostVideoAction, trigger: String) {
        guard !action.isNoop else {
            Logger.player("post-video NOOP trigger=\(trigger) autoClose=\(BidscubeSDK.isAutoClose())")
            return
        }

        Logger.player("post-video trigger=\(trigger) autoClose=\(BidscubeSDK.isAutoClose()) release=\(action.releasePlayer) hide=\(action.hidePlayer) keep=\(action.keepPlayerVisible) close=\(action.fireAdClosed)")

        if action.removeSkipOverlay {
            destroySkipOverlay()
        }

        if action.releasePlayer {
            adsManager?.destroy()
            adsManager = nil
            contentPlayer = nil
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
            contentPlayhead = nil
        }

        if action.hidePlayer {
            isHidden = true
        } else if action.keepPlayerVisible {
            isHidden = false
        }

        if action.showStaticCompanionEndCard, let companion = postVideoCompanion, staticEndCard == nil {
            hideHandlerCloseButton()
            showCompanionEndCard(companion)
        }

        if action.showHtmlCompanionEndCard, let companion = postVideoCompanion, htmlEndCard == nil {
            hideHandlerCloseButton()
            showCompanionEndCard(companion)
        }

        if action.showManualCloseButton {
            showCloseButton()
            if let adViewController = findViewController() as? AdViewController {
                adViewController.setVideoPlayingState(false)
                adViewController.enableSwipeGestures()
                adViewController.showBackButtonOnVideoComplete()
            }
        }

        if action.fireAdClosed {
            dismissFullscreenAdOnce(notifyClosed: true)
        }
    }

    private func showCompanionEndCard(_ companion: CompanionAd) {
        guard let hostView = superview else { return }
        let endCard = CompanionEndCardView(
            companion: companion,
            placementId: placementId,
            callback: callback,
            onRequestClose: { [weak self] in
                self?.requestUserClose()
            }
        )
        hostView.addSubview(endCard)
        NSLayoutConstraint.activate([
            endCard.topAnchor.constraint(equalTo: hostView.topAnchor),
            endCard.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            endCard.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            endCard.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])
        if companion.isStaticImage {
            staticEndCard = endCard
        } else {
            htmlEndCard = endCard
        }
    }

    private func dismissFullscreenAdOnce(notifyClosed: Bool = true) {
        let performDismiss = { [self] in
            guard !didDismissUI else { return }
            didDismissUI = true

            staticEndCard?.destroy()
            staticEndCard = nil
            htmlEndCard?.destroy()
            htmlEndCard = nil
            cleanup()

            FullscreenDismissalHelper.performFallbackDismissal(
                from: self,
                notifyClosed: notifyClosed,
                placementId: placementId,
                callback: callback,
                onNeedsReset: { [weak self] in self?.didDismissUI = false },
                logTag: "IMAVideoAdHandler"
            )
        }

        if Thread.isMainThread {
            performDismiss()
        } else {
            DispatchQueue.main.async(execute: performDismiss)
        }
    }

    private func hideHandlerCloseButton() {
        navigationChrome?.hide()
    }

    private func attachSkipOverlayIfNeeded() {
        guard skipOverlay == nil else { return }
        let overlay = VideoSkipControlOverlay(vastXml: vastXML, delegate: self)
        overlay.attach(to: self)
        skipOverlay = overlay
        navigationChrome?.bringToFront(in: self)
    }

    private func destroySkipOverlay() {
        skipOverlay?.destroy()
        skipOverlay = nil
    }
    
    private func closeAd() {
        requestUserClose()
    }
    
    private func showCloseButton() {
        DispatchQueue.main.async {
            self.navigationChrome?.show()
            self.navigationChrome?.bringToFront(in: self)
        }
    }

    private func hideCloseButton() {
        navigationChrome?.hide(animated: true)
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                print(" IMAVideoAdHandler: Found view controller in responder chain: \(type(of: viewController))")
                
                if let hostingController = viewController as? UIHostingController<AnyView> {
                    print("   - SwiftUI hosting controller detected")
                    return hostingController
                }
                
                if let navController = viewController as? UINavigationController {
                    print("   - Navigation controller detected, using top view controller")
                    return navController.topViewController ?? navController
                }
                
                var topVC = viewController
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }
                
                return topVC
            }
            responder = responder?.next
        }
        print("Error: IMAVideoAdHandler: No view controller found in responder chain")
        return nil
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("Error: IMAVideoAdHandler: No window found")
            return nil
        }
        
        guard let rootVC = window.rootViewController else {
            print("Error: IMAVideoAdHandler: No root view controller found")
            return nil
        }
        
        if let hostingController = rootVC as? UIHostingController<AnyView> {
            print(" IMAVideoAdHandler: Found SwiftUI hosting controller: \(type(of: hostingController))")
            return hostingController
        }
        
        if let navController = rootVC as? UINavigationController {
            print(" IMAVideoAdHandler: Found navigation controller, using top view controller")
            return navController.topViewController ?? navController
        }
        
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        
        print(" IMAVideoAdHandler: Using top view controller: \(type(of: topVC))")
        return topVC
    }

    private func findContentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                if let navController = viewController as? UINavigationController {
                    if let topVC = navController.topViewController {
                        return topVC
                    }
                } else if !(viewController is UINavigationController) {
                    return viewController
                }
            }
            responder = responder?.next
        }
        return nil
    }
    
    private func findStableViewController() -> UIViewController? {
        let candidates: [UIViewController?] = [
            parentViewController,
            findContentViewController(),
            findViewController(),
            getRootViewController()
        ]

        for candidate in candidates {
            guard let viewController = candidate else { continue }
            guard viewController.isViewLoaded, viewController.view.window != nil else { continue }
            logDiagnostics(
                "stable_presenter id=\(FullscreenLifecycleDiagnostics.objectID(viewController)) window=\(FullscreenLifecycleDiagnostics.objectID(viewController.view.window))"
            )
            return viewController
        }

        logDiagnostics(
            "ima_presenter_unavailable viewInWindow=\(window != nil) parentAttached=\(parentViewController?.view.window != nil)"
        )
        return nil
    }
}

extension IMAVideoAdHandler {
    var bidscubeTesting_containerCreatedCount: Int { containerCreatedCount }
    var bidscubeTesting_requestAdsCount: Int { requestAdsCount }
    var bidscubeTesting_activeContainerId: String? { activeContainerId }
    var bidscubeTesting_hasRequestedAds: Bool { hasRequestedAds }
    var bidscubeTesting_adDisplayContainer: IMAAdDisplayContainer? { adDisplayContainer }
    var bidscubeTesting_adsLoader: IMAAdsLoader? { adsLoader }
    var bidscubeTesting_playerLayer: AVPlayerLayer? { playerLayer }
}

extension IMAVideoAdHandler: IMAAdsLoaderDelegate {
    
    public func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        Logger.player("IMA ads loaded successfully for placement \(placementId)")
        logDiagnostics("adsLoaded manager=\(FullscreenLifecycleDiagnostics.objectID(adsLoadedData.adsManager))")

        dispatchOnMain { [weak self] in
            guard let self else { return }
            self.adsManager = adsLoadedData.adsManager
            self.adsManager?.delegate = self
            self.adsManager?.initialize(with: nil)
            self.callback?.onAdLoaded(self.placementId)
        }
    }
    
    public func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        let errorMessage = adErrorData.adError.message ?? "Unknown error"
        let errorCode = adErrorData.adError.code.rawValue
        
        Logger.error("IMA failed to load ads for placement \(placementId): \(errorMessage)", prefix: Constants.LogPrefixes.player)
        print("   - Error code: \(errorCode)")
        print("   - Error type: \(adErrorData.adError.type)")
        
        
        var userFriendlyMessage = errorMessage
        
        
        if errorMessage.contains("VAST") || errorMessage.contains("No Ads") {
            userFriendlyMessage = "No ads available for this placement. The ad type could be mismatch, try different placementId"
        } else if errorMessage.contains("timeout") {
            userFriendlyMessage = "Ad loading timeout. Please check your network connection"
        } else if errorMessage.contains("malformed") {
            userFriendlyMessage = "Invalid ad response format"
        } else if errorMessage.contains("redirect") {
            userFriendlyMessage = "Too many ad redirects. Please try again"
        } else if errorMessage.contains("network") {
            userFriendlyMessage = "Network error. Please check your internet connection"
        } else if errorMessage.contains("load") {
            userFriendlyMessage = "Ad loading failed. Please try again"
        } else if errorMessage.contains("play") {
            userFriendlyMessage = "Ad playback failed"
        } else {
            
            userFriendlyMessage = errorMessage
        }
        
        callback?.onAdFailed(placementId, errorCode: errorCode, errorMessage: userFriendlyMessage)
    }
}

extension IMAVideoAdHandler: IMAAdsManagerDelegate {
    
    public func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        Logger.player("IMA event for placement \(placementId): \(event.type)")
        
        switch event.type {
        case .LOADED:
            Logger.player("IMA player loaded ad and is starting playback for placement \(placementId)")
            adsManager.start()
            
        case .STARTED:
            Logger.player("IMA player started playback for placement \(placementId)")
            isPlaybackActive = true
            logDiagnostics("STARTED manager=\(FullscreenLifecycleDiagnostics.objectID(adsManager))")
            dispatchOnMain { [weak self] in
                guard let self else { return }
                self.callback?.onAdDisplayed(self.placementId)
                self.callback?.onVideoAdStarted(self.placementId)
                self.hideCloseButton()
                self.attachSkipOverlayIfNeeded()
                if let adViewController = self.findViewController() as? AdViewController {
                    adViewController.setVideoPlayingState(true)
                    adViewController.disableSwipeGestures()
                    adViewController.cancelLoadingTimeoutIfNeeded(reason: "IMA_STARTED")
                }
            }
            
        case .COMPLETE:
            Logger.player("IMA player completed playback for placement \(placementId)")
            ensureSessionController()
            if sessionController?.shouldFireLinearCompleted() == true {
                callback?.onVideoAdCompleted(placementId)
            }
            if let sessionController {
                applyPostVideoAction(sessionController.onLinearCompleted(), trigger: "COMPLETED")
            }
            
        case .SKIPPED:
            Logger.player("IMA player skipped playback for placement \(placementId)")
            ensureSessionController()
            if sessionController?.shouldFireSkipped() == true {
                callback?.onVideoAdSkipped(placementId)
            }
            if let sessionController {
                applyPostVideoAction(sessionController.onSkipped(), trigger: "SKIPPED")
            }

        case .ALL_ADS_COMPLETED:
            Logger.player("IMA all ads completed for placement \(placementId)")
            ensureSessionController()
            if sessionController?.shouldFireAdSessionCompleted() == true, let sessionController {
                applyPostVideoAction(sessionController.onAdSessionCompleted(), trigger: "ALL_ADS_COMPLETED")
            }
            
        case .CLICKED:
            Logger.player("IMA player click event for placement \(placementId)")
            callback?.onAdClicked(placementId)
            
        case .PAUSE:
            Logger.player("IMA player paused for placement \(placementId)")
            
            
            if let adViewController = findViewController() as? AdViewController {
                adViewController.setVideoPlayingState(false)
                adViewController.enableSwipeGestures()
            }
            
        case .RESUME:
            Logger.player("IMA player resumed for placement \(placementId)")
            
            
            if let adViewController = findViewController() as? AdViewController {
                adViewController.setVideoPlayingState(true)
                adViewController.disableSwipeGestures()
            }
            
        default:
            Logger.player("IMA player other event for placement \(placementId): \(event.type)")
        }
    }
    
    public func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        Logger.error("IMA player error for placement \(placementId): \(error.message ?? "Unknown error")", prefix: Constants.LogPrefixes.player)
        callback?.onAdFailed(placementId, errorCode: error.code.rawValue, errorMessage: error.message ?? "Unknown error")
        self.adsManager?.destroy()
        self.adsManager = nil
        if BidscubeSDK.isAutoClose() {
            dismissFullscreenAdOnce(notifyClosed: false)
            return
        }
        ensureSessionController()
        var action = FullscreenPostVideoAction()
        action.removeSkipOverlay = true
        action.releasePlayer = true
        action.hidePlayer = true
        action.showManualCloseButton = true
        applyPostVideoAction(action, trigger: "PLAYBACK_FAILED")
    }
    
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        print("⏸️ IMAVideoAdHandler: Content pause requested")
        contentPlayer?.pause()
    }
    
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        print("▶️ IMAVideoAdHandler: Content resume requested")
        contentPlayer?.play()
    }
}

extension IMAVideoAdHandler: VideoSkipControlOverlay.Delegate {
    func onSkipRequested() {
        adsManager?.skip()
    }

    func onSkipAvailable() {
        callback?.onVideoAdSkippable(placementId)
    }
}
