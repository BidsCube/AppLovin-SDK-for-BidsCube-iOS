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
    
    private var closeButton: UIButton?
    private var sessionController: FullscreenVideoSessionController?
    private var postVideoCompanion: CompanionAd?
    private var staticEndCard: CompanionEndCardView?
    private var htmlEndCard: CompanionEndCardView?
    private var skipOverlay: VideoSkipControlOverlay?
    
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
        print("🔄 IMAVideoAdHandler: Refreshing IMA setup due to view controller hierarchy change")
        
        adsManager?.destroy()
        adsManager = nil
        adDisplayContainer = nil
        
        let viewController: UIViewController? = findStableViewController() ?? createFallbackViewController()
        
        if let vc = viewController {
            adDisplayContainer = IMAAdDisplayContainer(adContainer: self, viewController: vc)
            print(" IMAVideoAdHandler: Recreated ad display container with view controller: \(type(of: vc))")
        } else {
            print("Error: IMAVideoAdHandler: Failed to find view controller for refreshed setup")
        }
    }
    
    public func cleanup() {
        destroySkipOverlay()
        staticEndCard?.destroy()
        staticEndCard = nil
        htmlEndCard?.destroy()
        htmlEndCard = nil

        adsManager?.destroy()
        adsManager = nil
        
        adsLoader = nil
        
        adDisplayContainer = nil
        
        contentPlayer = nil
        playerLayer = nil
        contentPlayhead = nil
        
        gestureRecognizers?.forEach { removeGestureRecognizer($0) }
        
        backgroundColor = .clear
    }
    
    deinit {
        cleanup()
    }
    
    public func loadAd() {
        ensureSessionController()
        if adsLoader == nil || adDisplayContainer == nil {
            Logger.player("Setting up IMA player before loading ad for placement \(placementId)")
            setupIMA()
        }
        
        guard let adsLoader = adsLoader else {
            print("Error: IMAVideoAdHandler: AdsLoader not initialized")
            return
        }
        
        guard let adDisplayContainer = adDisplayContainer else {
            print("Error: IMAVideoAdHandler: AdDisplayContainer not initialized")
            return
        }
        
        Logger.player("IMA player is ready. Starting ad load for placement \(placementId)")
        
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
        
        setupCloseButton()
    }
    
    private func setupCloseButton() {
        closeButton = UIButton(type: .system)
        closeButton?.setTitle("✕", for: .normal)
        closeButton?.setTitleColor(.white, for: .normal)
        closeButton?.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        closeButton?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        closeButton?.layer.cornerRadius = 20
        closeButton?.layer.borderWidth = 2
        closeButton?.layer.borderColor = UIColor.white.cgColor
        closeButton?.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton?.isHidden = true
        
        if let closeButton = closeButton {
            addSubview(closeButton)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                closeButton.widthAnchor.constraint(equalToConstant: 40),
                closeButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
        
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeGesture.direction = .right
        addGestureRecognizer(swipeGesture)
        
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
    }
    
    private func setupIMA() {
        contentPlayer = AVPlayer()
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: contentPlayer!)
        
        playerLayer = AVPlayerLayer(player: contentPlayer)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = bounds
        if let layer = playerLayer {
            self.layer.addSublayer(layer)
        }
        
        let viewController: UIViewController? = findStableViewController() ?? createFallbackViewController()
        
        if let vc = viewController {
            adDisplayContainer = IMAAdDisplayContainer(adContainer: self, viewController: vc)
            print(" IMAVideoAdHandler: Using view controller: \(type(of: vc))")
            print("   - VC description: \(vc.description)")
            print("   - Parent: \(vc.parent?.description ?? "nil")")
            print("   - Nav: \(vc.navigationController?.description ?? "nil")")
        } else {
            print("Error: IMAVideoAdHandler: No view controller available for IMAAdDisplayContainer")
        }
        
        Logger.player("Initializing default IMA player for placement \(placementId)")
        let settings = IMASettings()
        settings.enableDebugMode = true
        settings.maxRedirects = 5  
        settings.autoPlayAdBreaks = true
        settings.language = "en"
        adsLoader = IMAAdsLoader(settings: settings)
        adsLoader?.delegate = self
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
            dismissFullscreenAdOnce()
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

    private func dismissFullscreenAdOnce() {
        staticEndCard?.destroy()
        staticEndCard = nil
        htmlEndCard?.destroy()
        htmlEndCard = nil
        cleanup()

        if let adViewController = findViewController() as? AdViewController {
            adViewController.dismissAdOnce()
            return
        }

        callback?.onAdClosed(placementId)
        if let viewController = findViewController() {
            if viewController.presentingViewController != nil {
                viewController.dismiss(animated: true)
            } else if let navigationController = viewController.navigationController {
                navigationController.popViewController(animated: true)
            }
        }
    }

    private func hideHandlerCloseButton() {
        closeButton?.isHidden = true
    }

    private func attachSkipOverlayIfNeeded() {
        guard skipOverlay == nil else { return }
        let overlay = VideoSkipControlOverlay(vastXml: vastXML, delegate: self)
        overlay.attach(to: self)
        skipOverlay = overlay
        if let closeButton {
            bringSubviewToFront(closeButton)
        }
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
            self.closeButton?.isHidden = false
            self.closeButton?.alpha = 0
            
            UIView.animate(withDuration: 0.3, delay: 0.5, options: .curveEaseInOut) {
                self.closeButton?.alpha = 1.0
            }
        }
    }
    
    private func hideCloseButton() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.closeButton?.alpha = 0
            } completion: { _ in
                self.closeButton?.isHidden = true
            }
        }
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
    
    private func createFallbackViewController() -> UIViewController? {
        let fallbackVC = UIViewController()
        fallbackVC.view.backgroundColor = .clear
        print(" IMAVideoAdHandler: Created fallback view controller")
        return fallbackVC
    }
    
    private func findContentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                if let navController = viewController as? UINavigationController {
                    if let topVC = navController.topViewController {
                        print(" IMAVideoAdHandler: Found content view controller in navigation: \(type(of: topVC))")
                        return topVC
                    }
                } else if !(viewController is UINavigationController) {
                    print(" IMAVideoAdHandler: Found content view controller: \(type(of: viewController))")
                    return viewController
                }
            }
            responder = responder?.next
        }
        return nil
    }
    
    private func findStableViewController() -> UIViewController? {
        let candidates = [
            parentViewController,
            findContentViewController(),
            findViewController(),
            getRootViewController()
        ]
        
        for candidate in candidates {
            if let vc = candidate {
                if vc.isViewLoaded && vc.view.window != nil {
                    print(" IMAVideoAdHandler: Found stable view controller: \(type(of: vc))")
                    return vc
                }
            }
        }
        
        for candidate in candidates {
            if let vc = candidate {
                print("⚠️ IMAVideoAdHandler: Using fallback view controller: \(type(of: vc))")
                return vc
            }
        }
        
        return nil
    }
}

extension IMAVideoAdHandler: IMAAdsLoaderDelegate {
    
    public func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        Logger.player("IMA ads loaded successfully for placement \(placementId)")
        
        adsManager = adsLoadedData.adsManager
        
        adsManager?.delegate = self
        adsManager?.initialize(with: nil)
        
        callback?.onAdLoaded(placementId)
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
            callback?.onVideoAdStarted(placementId)
            hideCloseButton()
            attachSkipOverlayIfNeeded()
            
            
            if let adViewController = findViewController() as? AdViewController {
                adViewController.setVideoPlayingState(true)
                adViewController.disableSwipeGestures()
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
        ensureSessionController()
        applyPostVideoAction(sessionController?.onPlaybackFailed() ?? .noop, trigger: "PLAYBACK_FAILED")
        callback?.onAdFailed(placementId, errorCode: error.code.rawValue, errorMessage: error.message ?? "Unknown error")
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
