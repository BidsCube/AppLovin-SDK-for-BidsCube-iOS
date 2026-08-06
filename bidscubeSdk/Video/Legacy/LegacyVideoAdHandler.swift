import AVFoundation
import UIKit

/// AVPlayer-based VAST player for the legacy iOS 14 pod (no Google IMA dependency).
public final class LegacyVideoAdHandler: UIView, BidscubeCustomVideoPlayer {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var itemStatusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var resolvedAd: ResolvedVastAd?
    private var vastXml: String?
    private var placementId = ""
    private weak var callback: AdCallback?
    private weak var parentViewController: UIViewController?
    private var fallbackClickURL: String?

    private var closeButton: UIButton?
    private var sessionController: FullscreenVideoSessionController?
    private var postVideoCompanion: CompanionAd?
    private var staticEndCard: CompanionEndCardView?
    private var htmlEndCard: CompanionEndCardView?
    private var skipOverlay: VideoSkipControlOverlay?

    private var callbackGuard = VideoCallbackGuard()
    private var trackingContext = VastTrackingContext()
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var notificationTokens: [NSObjectProtocol] = []
    private var prepareTimeoutTimer: Timer?
    private var stallRecoveryTimer: Timer?
    private var loadSessionId = UUID()
    private var resolutionErrorURLs: [String] = []
    private var didDismissUI = false

    private var prepareTimeoutSeconds: TimeInterval {
        let timeoutMs = BidscubeSDK.getConfiguration()?.defaultAdTimeoutMs ?? Constants.defaultTimeoutMs
        return TimeInterval(timeoutMs) / 1000.0
    }
    private let stallTimeoutSeconds: TimeInterval = 15

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    deinit {
        cleanup()
    }

    public func setPlacementInfo(_ placementId: String, callback: AdCallback?) {
        self.placementId = placementId
        self.callback = callback
    }

    public func setParentViewController(_ viewController: UIViewController?) {
        parentViewController = viewController
    }

    public func loadVAST(source: String, isURL: Bool, clickURL: String?) {
        cleanupPlayback(keepSession: false)
        callbackGuard = VideoCallbackGuard()
        fallbackClickURL = clickURL
        resolutionErrorURLs = []
        isHidden = false
        let sessionId = UUID()
        loadSessionId = sessionId

        VastResolver.resolve(source: source, isURL: isURL) { [weak self] result in
            guard let self, self.loadSessionId == sessionId, !self.callbackGuard.hasFailed else { return }
            switch result {
            case .failure(let failure):
                self.resolutionErrorURLs = failure.collectedErrorURLs
                self.handleFailure(
                    failure.requestError.message,
                    code: failure.requestError.errorCode,
                    vastErrorCode: failure.vastErrorCode
                )
            case .success(let ad):
                self.beginPlayback(ad: ad, sessionId: sessionId)
            }
        }
    }

    public func cleanup() {
        cancelPrepareTimeout()
        cancelStallRecoveryTimer()
        removeLifecycleObservers()
        removeItemObservers()
        destroySkipOverlay()
        staticEndCard?.destroy()
        staticEndCard = nil
        htmlEndCard?.destroy()
        htmlEndCard = nil
        cleanupPlayback(keepSession: false)
        sessionController = nil
        postVideoCompanion = nil
        resolvedAd = nil
    }

    public func refreshIMASetup() {
        // Legacy player does not use IMA; no-op for API parity with VideoAdView.
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    private func setupView() {
        backgroundColor = .black
        isUserInteractionEnabled = true
        setupCloseButton()
        registerLifecycleObservers()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    private func beginPlayback(ad: ResolvedVastAd, sessionId: UUID) {
        guard loadSessionId == sessionId, !callbackGuard.hasFailed else { return }
        resolvedAd = ad
        vastXml = ad.vastXml
        trackingContext.assetURI = ad.inlineAd.mediaURL.absoluteString
        postVideoCompanion = ad.companion ?? VastParser.selectPostVideoCompanion(ad.vastXml)
        sessionController = FullscreenVideoSessionController(
            autoClose: BidscubeSDK.isAutoClose(),
            playerManagesPostVideo: false,
            vastXml: ad.vastXml
        )

        let item = AVPlayerItem(url: ad.inlineAd.mediaURL)
        playerItem = item
        let player = AVPlayer(playerItem: item)
        self.player = player

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        layer.frame = bounds
        self.layer.insertSublayer(layer, at: 0)
        playerLayer = layer

        observePlayerItem(item)
        observeTimeControlStatus(player)
        addTimeObserver(for: player)
        startPrepareTimeout()

        if let adViewController = findViewController() as? AdViewController {
            adViewController.setVideoPlayingState(true)
            adViewController.disableSwipeGestures()
        }
    }

    private func observePlayerItem(_ item: AVPlayerItem) {
        itemStatusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async { self?.handleItemStatus(item) }
        }

        let center = NotificationCenter.default
        notificationTokens.append(center.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in self?.playerDidFinish() })

        notificationTokens.append(center.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] note in
            let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError
            self?.handleFailure(
                error?.localizedDescription ?? "Playback failed",
                code: error?.code ?? AdErrorCode.invalidResponse,
                vastErrorCode: 405
            )
        })

        notificationTokens.append(center.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackStalled()
        })
    }

    private func observeTimeControlStatus(_ player: AVPlayer) {
        timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async { self?.handleTimeControlStatus(player.timeControlStatus) }
        }
    }

    private func handleItemStatus(_ item: AVPlayerItem) {
        guard !callbackGuard.hasFailed else { return }
        switch item.status {
        case .readyToPlay:
            cancelPrepareTimeout()
            callbackGuard.fireOnce("loaded") { [weak self] in
                guard let self else { return }
                self.callback?.onAdLoaded(self.placementId)
            }
            player?.play()
        case .failed:
            let nsError = item.error as NSError?
            handleFailure(
                item.error?.localizedDescription ?? "Media failed to load",
                code: nsError?.code ?? AdErrorCode.invalidResponse,
                vastErrorCode: 403
            )
        default:
            break
        }
    }

    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        guard status == .playing else { return }
        cancelStallRecoveryTimer()
        markPlaybackStartedIfNeeded(at: player?.currentTime() ?? .zero)
    }

    private func handlePlaybackStalled() {
        Logger.player("Legacy player stalled; starting recovery timer")
        cancelStallRecoveryTimer()
        stallRecoveryTimer = Timer.scheduledTimer(withTimeInterval: stallTimeoutSeconds, repeats: false) { [weak self] _ in
            self?.handleFailure("Playback stalled", code: AdErrorCode.networkError, vastErrorCode: 405)
        }
        player?.play()
    }

    private func startPrepareTimeout() {
        cancelPrepareTimeout()
        prepareTimeoutTimer = Timer.scheduledTimer(withTimeInterval: prepareTimeoutSeconds, repeats: false) { [weak self] _ in
            self?.handleFailure("Media prepare timeout", code: AdErrorCode.networkError, vastErrorCode: 301)
        }
    }

    private func cancelPrepareTimeout() {
        prepareTimeoutTimer?.invalidate()
        prepareTimeoutTimer = nil
    }

    private func cancelStallRecoveryTimer() {
        stallRecoveryTimer?.invalidate()
        stallRecoveryTimer = nil
    }

    private func addTimeObserver(for player: AVPlayer) {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handlePeriodicTime(time)
        }
    }

    @objc private func playerDidFinish() {
        guard !callbackGuard.hasFired("complete") else { return }
        callbackGuard.fireOnce("complete") { [weak self] in
            guard let self else { return }
            self.fireTracking("complete")
            self.ensureSessionController()
            if self.sessionController?.shouldFireLinearCompleted() == true {
                self.callback?.onVideoAdCompleted(self.placementId)
            }
            if let sessionController = self.sessionController {
                self.applyPostVideoAction(sessionController.onLinearCompleted(), trigger: "COMPLETED")
            }
        }
    }

    private func handlePeriodicTime(_ time: CMTime) {
        trackingContext.playheadSeconds = time.seconds
        guard let duration = player?.currentItem?.duration,
              duration.isNumeric,
              duration.seconds > 0 else {
            if time.seconds > 0.05 {
                markPlaybackStartedIfNeeded(at: time)
            }
            return
        }

        if time.seconds > 0.05 {
            markPlaybackStartedIfNeeded(at: time)
        }

        let progress = time.seconds / duration.seconds
        if !callbackGuard.hasFired("firstQuartile"), progress >= 0.25 {
            callbackGuard.fireOnce("firstQuartile") { [weak self] in self?.fireTracking("firstquartile") }
        }
        if !callbackGuard.hasFired("midpoint"), progress >= 0.5 {
            callbackGuard.fireOnce("midpoint") { [weak self] in self?.fireTracking("midpoint") }
        }
        if !callbackGuard.hasFired("thirdQuartile"), progress >= 0.75 {
            callbackGuard.fireOnce("thirdQuartile") { [weak self] in self?.fireTracking("thirdquartile") }
        }
    }

    private func markPlaybackStartedIfNeeded(at time: CMTime) {
        guard time.seconds > 0.05 else { return }
        callbackGuard.fireOnce("displayed") { [weak self] in
            guard let self else { return }
            self.callback?.onAdDisplayed(self.placementId)
        }
        callbackGuard.fireOnce("impression") { [weak self] in
            guard let self, let resolvedAd = self.resolvedAd else { return }
            TrackerPinger.pingUrls("impression", resolvedAd.mergedImpressionURLs, context: self.trackingContext)
        }
        callbackGuard.fireOnce("start") { [weak self] in
            guard let self else { return }
            self.callback?.onVideoAdStarted(self.placementId)
            self.fireTracking("start")
            self.attachSkipOverlayIfNeeded()
            self.hideCloseButton()
        }
    }

    private func currentTrackingContext() -> VastTrackingContext {
        var context = trackingContext
        context.playheadSeconds = player?.currentTime().seconds ?? trackingContext.playheadSeconds
        if context.assetURI.isEmpty {
            context.assetURI = resolvedAd?.inlineAd.mediaURL.absoluteString ?? ""
        }
        return context
    }

    private func fireTracking(_ event: String) {
        guard let urls = resolvedAd?.mergedTrackingEvents[event.lowercased()], !urls.isEmpty else { return }
        TrackerPinger.pingUrls(event, urls, context: currentTrackingContext())
    }

    @objc private func handleTap() {
        guard resolvedAd != nil else { return }
        callbackGuard.fireOnce("clicked") { [weak self] in
            guard let self else { return }
            self.callback?.onAdClicked(self.placementId)
        }
        if let resolvedAd {
            TrackerPinger.pingUrls(
                "clickTracking",
                resolvedAd.mergedClickTrackingURLs,
                context: currentTrackingContext()
            )
        }
        let clickThrough = resolvedAd?.inlineAd.clickThroughUrl ?? fallbackClickURL
        if let clickThrough, let url = URL(string: clickThrough) {
            UIApplication.shared.open(url, options: [:])
        }
    }

    @objc private func closeButtonTapped() {
        requestUserClose()
    }

    private func requestUserClose() {
        fireTracking("close")
        fireTracking("closelinear")
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

    private func handleFailure(_ message: String, code: Int, vastErrorCode: Int) {
        guard !callbackGuard.hasFailed else { return }

        let errorURLs = resolvedAd?.mergedErrorURLs ?? resolutionErrorURLs
        if !errorURLs.isEmpty {
            TrackerPinger.pingUrls(
                "error",
                errorURLs,
                context: currentTrackingContext(),
                errorCode: vastErrorCode
            )
        }

        callbackGuard.fireOnce("failed") { [weak self] in
            guard let self else { return }
            self.callback?.onAdFailed(self.placementId, errorCode: code, errorMessage: message)
        }

        cancelPrepareTimeout()
        cancelStallRecoveryTimer()
        destroySkipOverlay()
        cleanupPlayback(keepSession: false)

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

    private func ensureSessionController() {
        if sessionController != nil { return }
        sessionController = FullscreenVideoSessionController(
            autoClose: BidscubeSDK.isAutoClose(),
            playerManagesPostVideo: false,
            vastXml: vastXml
        )
        if let vastXml {
            postVideoCompanion = VastParser.selectPostVideoCompanion(vastXml)
        }
    }

    private func applyPostVideoAction(_ action: FullscreenPostVideoAction, trigger: String) {
        guard !action.isNoop else { return }
        Logger.player("legacy post-video trigger=\(trigger) autoClose=\(BidscubeSDK.isAutoClose())")

        if action.removeSkipOverlay { destroySkipOverlay() }
        if action.releasePlayer { cleanupPlayback(keepSession: true) }
        if action.hidePlayer { isHidden = true }
        else if action.keepPlayerVisible { isHidden = false }

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
        if let resolvedAd {
            TrackerPinger.pingUrls(
                "creativeView",
                resolvedAd.companionCreativeViewURLs,
                context: currentTrackingContext()
            )
        }
        let endCard = CompanionEndCardView(
            companion: companion,
            placementId: placementId,
            callback: callback,
            onRequestClose: { [weak self] in self?.requestUserClose() }
        )
        hostView.addSubview(endCard)
        NSLayoutConstraint.activate([
            endCard.topAnchor.constraint(equalTo: hostView.topAnchor),
            endCard.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            endCard.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            endCard.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])
        if companion.isStaticImage { staticEndCard = endCard }
        else { htmlEndCard = endCard }
    }

    private func dismissFullscreenAdOnce(notifyClosed: Bool = true) {
        guard !didDismissUI else { return }
        didDismissUI = true

        staticEndCard?.destroy()
        staticEndCard = nil
        htmlEndCard?.destroy()
        htmlEndCard = nil
        cleanup()

        if let adViewController = findViewController() as? AdViewController {
            adViewController.dismissAdOnce(notifyClosed: notifyClosed)
            return
        }
        if notifyClosed {
            callback?.onAdClosed(placementId)
        }
        findViewController()?.dismiss(animated: true)
    }

    private func cleanupPlayback(keepSession: Bool) {
        cancelPrepareTimeout()
        cancelStallRecoveryTimer()
        removeItemObservers()
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        player?.pause()
        player = nil
        playerItem = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        if !keepSession {
            resolvedAd = nil
            vastXml = nil
        }
    }

    private func removeItemObservers() {
        itemStatusObserver?.invalidate()
        itemStatusObserver = nil
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
        notificationTokens.removeAll()
    }

    private func setupCloseButton() {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
        closeButton = button
    }

    private func showCloseButton() {
        DispatchQueue.main.async {
            self.closeButton?.isHidden = false
            self.closeButton?.alpha = 0
            UIView.animate(withDuration: 0.3, delay: 0.5) { self.closeButton?.alpha = 1 }
        }
    }

    private func hideCloseButton() {
        closeButton?.isHidden = true
    }

    private func hideHandlerCloseButton() {
        closeButton?.isHidden = true
    }

    private func attachSkipOverlayIfNeeded() {
        guard skipOverlay == nil else { return }
        let overlay = VideoSkipControlOverlay(vastXml: vastXml, delegate: self)
        overlay.attach(to: self)
        skipOverlay = overlay
        if let closeButton { bringSubviewToFront(closeButton) }
    }

    private func destroySkipOverlay() {
        skipOverlay?.destroy()
        skipOverlay = nil
    }

    private func registerLifecycleObservers() {
        let center = NotificationCenter.default
        lifecycleObservers.append(center.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.player?.pause() })
        lifecycleObservers.append(center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, !self.callbackGuard.hasFired("complete"), !self.callbackGuard.hasFailed else { return }
            self.player?.play()
        })
    }

    private func removeLifecycleObservers() {
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        lifecycleObservers.removeAll()
    }

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController { return viewController }
            responder = current.next
        }
        return parentViewController
    }
}

extension LegacyVideoAdHandler: VideoSkipControlOverlay.Delegate {
    func onSkipRequested() {
        ensureSessionController()
        callbackGuard.fireOnce("skipped") { [weak self] in
            guard let self else { return }
            if self.sessionController?.shouldFireSkipped() == true {
                self.callback?.onVideoAdSkipped(self.placementId)
            }
            self.fireTracking("skip")
        }
        if let sessionController {
            applyPostVideoAction(sessionController.onSkipped(), trigger: "SKIPPED")
        }
    }

    func onSkipAvailable() {
        callbackGuard.fireOnce("skippable") { [weak self] in
            guard let self else { return }
            self.callback?.onVideoAdSkippable(self.placementId)
        }
    }
}

public final class BidscubeLegacyVideoPlayerFactory: BidscubeCustomVideoPlayerFactory {
    public init() {}

    public func makeVideoPlayer() -> UIView & BidscubeCustomVideoPlayer {
        LegacyVideoAdHandler()
    }
}
