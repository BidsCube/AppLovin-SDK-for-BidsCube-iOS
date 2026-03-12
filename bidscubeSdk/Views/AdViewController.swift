import UIKit
import bidscubeSdk


private class AdCallbackWrapper: AdCallback {
    private let originalCallback: AdCallback?
    private let errorHandler: (String, Int, String) -> Void
    private let successHandler: (String) -> Void
    
    init(originalCallback: AdCallback?, 
         errorHandler: @escaping (String, Int, String) -> Void,
         successHandler: @escaping (String) -> Void) {
        self.originalCallback = originalCallback
        self.errorHandler = errorHandler
        self.successHandler = successHandler
    }
    
    func onAdLoading(_ placementId: String) {
        originalCallback?.onAdLoading(placementId)
    }
    
    func onAdLoaded(_ placementId: String) {
        successHandler(placementId)
        originalCallback?.onAdLoaded(placementId)
    }
    
    func onAdDisplayed(_ placementId: String) {
        originalCallback?.onAdDisplayed(placementId)
    }
    
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        errorHandler(placementId, errorCode, errorMessage)
        originalCallback?.onAdFailed(placementId, errorCode: errorCode, errorMessage: errorMessage)
    }
    
    func onAdClicked(_ placementId: String) {
        originalCallback?.onAdClicked(placementId)
    }
    
    func onAdClosed(_ placementId: String) {
        originalCallback?.onAdClosed(placementId)
    }
    
    func onVideoAdStarted(_ placementId: String) {
        originalCallback?.onVideoAdStarted(placementId)
    }
    
    func onVideoAdCompleted(_ placementId: String) {
        originalCallback?.onVideoAdCompleted(placementId)
    }
    
    func onVideoAdSkipped(_ placementId: String) {
        originalCallback?.onVideoAdSkipped(placementId)
    }
}

public final class AdViewController: UIViewController {
    
    private let placementId: String
    private let adType: AdType
    private let callback: AdCallback?
    private var adView: UIView?
    private var backButton: UIButton!
    private var closeButton: UIButton?
    private var positionLabel: UILabel!
    private var currentPosition: AdPosition = .unknown
    private var loadingTimeoutTimer: Timer?
    private var hasAdLoaded = false
    private var swipeGestureRecognizer: UISwipeGestureRecognizer?
    private var doubleTapGestureRecognizer: UITapGestureRecognizer?
    private var isVideoPlaying = false
    
    public init(placementId: String, adType: AdType, callback: AdCallback? = nil) {
        self.placementId = placementId
        self.adType = adType
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAd()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        ensureBackButtonOnTop()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ensureBackButtonOnTop()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let videoAdView = adView as? VideoAdView {
            videoAdView.cleanup()
        }
        if let bannerAdView = adView as? BannerAdView {
            bannerAdView.detachFromScreen()
        }
        
        
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
    }
    
    deinit {
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.isHidden = true  
        
        closeButton = UIButton(type: .system)
        closeButton?.setTitle("✕", for: .normal)
        closeButton?.setTitleColor(.white, for: .normal)
        closeButton?.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        closeButton?.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton?.isHidden = true
        closeButton?.translatesAutoresizingMaskIntoConstraints = false
        
        positionLabel = UILabel()
        positionLabel.text = "Position: Loading..."
        positionLabel.font = UIFont.systemFont(ofSize: 14)
        positionLabel.textColor = .secondaryLabel
        positionLabel.textAlignment = .center
        positionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backButton)
        view.addSubview(closeButton!)
        view.addSubview(positionLabel)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            closeButton!.topAnchor.constraint(equalTo: backButton.topAnchor),
            closeButton!.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 24),
            closeButton!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton!.widthAnchor.constraint(equalToConstant: 40),
            closeButton!.heightAnchor.constraint(equalToConstant: 40),
            
            positionLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            positionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            positionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func loadAd() {
        callback?.onAdLoading(placementId)
        
        
        let timeoutDuration: TimeInterval = (adType == .video) ? 10.0 : 5.0
        loadingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutDuration, repeats: false) { [weak self] _ in
            self?.handleLoadingTimeout()
        }
        
        
        let errorHandlingCallback = AdCallbackWrapper(
            originalCallback: callback,
            errorHandler: { [weak self] placementId, errorCode, errorMessage in
                self?.handleAdError(placementId, errorCode: errorCode, errorMessage: errorMessage)
            },
            successHandler: { [weak self] placementId in
                self?.handleAdSuccess(placementId)
            }
        )
        
        switch adType {
        case .image:
            adView = BidscubeSDK.getImageAdView(placementId, errorHandlingCallback)
        case .video:
            adView = BidscubeSDK.getVideoAdView(placementId, errorHandlingCallback)
        case .native:
            adView = BidscubeSDK.getNativeAdView(placementId, errorHandlingCallback)
        }
        
        guard let adView = adView else {
            handleAdError(placementId, errorCode: -1, errorMessage: "Failed to create ad view")
            return
        }
        
        view.addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        
        if let videoAdView = adView as? VideoAdView {
            videoAdView.setParentViewController(self)
        }
        
        ensureBackButtonOnTop()
        
        setupAdConstraints(for: .unknown)
        
        startPositionMonitoring()
    }
    
    private func handleLoadingTimeout() {
        guard !hasAdLoaded else { return }
        
        print("🔍 AdViewController: Ad loading timeout")
        handleAdError(placementId, errorCode: -2, errorMessage: "Ad loading timeout")
    }
    
    private func handleAdSuccess(_ placementId: String) {
        hasAdLoaded = true
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
        
        print("🔍 AdViewController: Ad loaded successfully")
    }
    
    private func handleAdError(_ placementId: String, errorCode: Int, errorMessage: String) {
        print("🔍 AdViewController: Ad failed - \(errorMessage)")
        
        
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
        
        
        isVideoPlaying = false
        enableSwipeGestures()
        
        
        DispatchQueue.main.async {
            self.showBackButtonOnError()
        }
        
        
        callback?.onAdFailed(placementId, errorCode: errorCode, errorMessage: errorMessage)
    }
    
    private func showBackButtonOnError() {
        
        backButton.isHidden = false
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        backButton.setTitleColor(.white, for: .normal)
        backButton.layer.cornerRadius = 20
        backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        backButton.layer.shadowRadius = 4
        backButton.layer.shadowOpacity = 0.3
        
        
        positionLabel.text = "Ad failed to load"
        positionLabel.textColor = .systemRed
        positionLabel.isHidden = false
        
        
        view.bringSubviewToFront(backButton)
        view.bringSubviewToFront(positionLabel)
        
        
        showErrorMessage()
    }
    
    private func showErrorMessage() {
        let errorLabel = UILabel()
        errorLabel.text = "Video ad failed to load.\nTap back to return."
        errorLabel.textAlignment = .center
        errorLabel.textColor = .white
        errorLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        errorLabel.numberOfLines = 0
        errorLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        errorLabel.layer.cornerRadius = 8
        errorLabel.clipsToBounds = true
        
        view.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            errorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        
        
        errorLabel.alpha = 0
        UIView.animate(withDuration: 0.3) {
            errorLabel.alpha = 1.0
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            UIView.animate(withDuration: 0.3) {
                errorLabel.alpha = 0
            } completion: { _ in
                errorLabel.removeFromSuperview()
            }
        }
    }
    
    private func startPositionMonitoring() {
        var attempts = 0
        let maxAttempts = 20
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            attempts += 1
            let currentPosition = BidscubeSDK.getResponseAdPosition()
            
            if currentPosition != .unknown || attempts >= maxAttempts {
                timer.invalidate()
                self.updatePosition(currentPosition)
            }
        }
    }
    
    private func updatePosition(_ position: AdPosition) {
        currentPosition = position
        positionLabel.text = "Position: \(displayName(for: position))"
        
        setupAdConstraints(for: position)
        
        ensureBackButtonOnTop()
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    private func setupAdConstraints(for position: AdPosition) {
        guard let adView = adView else { return }
        
        adView.removeFromSuperview()
        view.addSubview(adView)
        adView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.deactivate(view.constraints.filter { constraint in
            constraint.firstItem === adView || constraint.secondItem === adView
        })
        
        updateCloseButtonConstraints(for: position)
        
        switch position {
        case .fullScreen:
            setupFullScreenLayout(adView)
        case .aboveTheFold:
            setupAboveTheFoldLayout(adView)
        case .belowTheFold:
            setupBelowTheFoldLayout(adView)
        case .header:
            setupHeaderLayout(adView)
        case .footer:
            setupFooterLayout(adView)
        case .sidebar:
            setupSidebarLayout(adView)
        case .dependOnScreenSize:
            setupScreenSizeDependentLayout(adView)
        case .unknown:
            setupDefaultLayout(adView)
        }
    }
    
    private func updateCloseButtonConstraints(for position: AdPosition) {
        guard let closeButton = closeButton else { return }
        
        closeButton.removeFromSuperview()
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: backButton.topAnchor),
            closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        view.bringSubviewToFront(closeButton)
    }
    
    private func setupFullScreenLayout(_ adView: UIView) {
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: view.topAnchor),
            adView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            adView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        positionLabel.isHidden = true
        
        
        
        
        backButton.removeFromSuperview()
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
        
        if let closeButton = closeButton {
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: backButton.topAnchor),
                closeButton.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 24),
                closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                closeButton.widthAnchor.constraint(equalToConstant: 40),
                closeButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
        
        view.bringSubviewToFront(backButton)
        
        
        setupFullScreenGestures()
    }
    
    private func setupFullScreenGestures() {
        
        swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleFullScreenSwipe))
        swipeGestureRecognizer?.direction = .right
        if let swipeGesture = swipeGestureRecognizer {
            view.addGestureRecognizer(swipeGesture)
        }
        
        
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleFullScreenDoubleTap))
        doubleTapGestureRecognizer?.numberOfTapsRequired = 2
        if let doubleTapGesture = doubleTapGestureRecognizer {
            view.addGestureRecognizer(doubleTapGesture)
        }
    }
    
   @objc private func handleFullScreenSwipe(_ gesture: UISwipeGestureRecognizer) {
    print("🔍 AdViewController: Fullscreen swipe gesture detected")
    guard !isVideoPlaying else {
        print("🔍 AdViewController: Swipe blocked - video is playing")
        return
    }
    backButtonTapped()
}

@objc private func handleFullScreenDoubleTap(_ gesture: UITapGestureRecognizer) {
    print("🔍 AdViewController: Fullscreen double tap gesture detected")
    guard !isVideoPlaying else {
        print("🔍 AdViewController: Double tap blocked - video is playing")
        return
    }
    closeButtonTapped()
}

    
    private func setupAboveTheFoldLayout(_ adView: UIView) {
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            adView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            adView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            adView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        resetBackButtonStyling()
        
        positionLabel.isHidden = false
    }
    
    private func setupBelowTheFoldLayout(_ adView: UIView) {
        NSLayoutConstraint.activate([
            adView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            adView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            adView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            adView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        resetBackButtonStyling()
        
        positionLabel.isHidden = false
    }
    
    private func setupHeaderLayout(_ adView: UIView) {
        
        if let bannerAdView = adView as? BannerAdView {
            bannerAdView.attachToScreen(in: self)
            resetBackButtonStyling()
            
            positionLabel.isHidden = false
            return
        }
        
        
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: positionLabel.bottomAnchor, constant: 20),
            adView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            adView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            adView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        resetBackButtonStyling()
        
        positionLabel.isHidden = false
    }
    
    private func setupFooterLayout(_ adView: UIView) {
        
        if let bannerAdView = adView as? BannerAdView {
            bannerAdView.attachToScreen(in: self)
            resetBackButtonStyling()
            
            positionLabel.isHidden = false
            return
        }
        
        
        NSLayoutConstraint.activate([
            adView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            adView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            adView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            adView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        resetBackButtonStyling()
        
        positionLabel.isHidden = false
    }
    
    private func setupSidebarLayout(_ adView: UIView) {
        
        if let bannerAdView = adView as? BannerAdView {
            bannerAdView.attachToScreen(in: self)
            resetBackButtonStyling()
            
            positionLabel.isHidden = false
            return
        }
        
        
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: positionLabel.bottomAnchor, constant: 20),
            adView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            adView.widthAnchor.constraint(equalToConstant: 150),
            adView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        resetBackButtonStyling()
        
        positionLabel.isHidden = false
    }
    
    private func setupScreenSizeDependentLayout(_ adView: UIView) {
        let screenHeight = UIScreen.main.bounds.height
        
        if screenHeight > 800 {
            setupAboveTheFoldLayout(adView)
        } else {
            setupHeaderLayout(adView)
        }
    }
    
    private func setupDefaultLayout(_ adView: UIView) {
        NSLayoutConstraint.activate([
            adView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            adView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            adView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            adView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
            adView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        resetBackButtonStyling()
        
        positionLabel.isHidden = false
    }
    
    @objc private func backButtonTapped() {
        callback?.onAdClosed(placementId)
        
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func closeButtonTapped() {
        
        callback?.onAdClosed(placementId)
        
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    private func ensureBackButtonOnTop() {
        if !backButton.isHidden {
            view.bringSubviewToFront(backButton)
        }
        
        if let closeButton = closeButton, !closeButton.isHidden {
            view.bringSubviewToFront(closeButton)
        }
        
        if !positionLabel.isHidden {
            view.bringSubviewToFront(positionLabel)
        }
    }
    
    private func displayName(for position: AdPosition) -> String {
        switch position {
        case .unknown: return "UNKNOWN"
        case .aboveTheFold: return "ABOVE_THE_FOLD"
        case .dependOnScreenSize: return "DEPEND_ON_SCREEN_SIZE"
        case .belowTheFold: return "BELOW_THE_FOLD"
        case .header: return "HEADER"
        case .footer: return "FOOTER"
        case .sidebar: return "SIDEBAR"
        case .fullScreen: return "FULL_SCREEN"
        }
    }
    
    private func resetBackButtonStyling() {
        backButton.backgroundColor = .clear
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.layer.cornerRadius = 0
        backButton.contentEdgeInsets = UIEdgeInsets.zero
        backButton.layer.shadowOpacity = 0
        
        ensureBackButtonOnTop()
    }
    
    public func showCloseButton() {
        DispatchQueue.main.async {
            self.closeButton?.isHidden = false
            self.closeButton?.alpha = 0
            
            UIView.animate(withDuration: 0.3, delay: 0.5, options: .curveEaseInOut) {
                self.closeButton?.alpha = 1.0
            }
            
            self.ensureBackButtonOnTop()
        }
    }
    
    public func showCloseButtonOnComplete() {
        DispatchQueue.main.async {
            self.closeButton?.isHidden = false
            self.closeButton?.alpha = 0
            
            UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseInOut) {
                self.closeButton?.alpha = 1.0
            }
            
            self.ensureBackButtonOnTop()
        }
    }
    
    public func hideCloseButton() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.closeButton?.alpha = 0
            } completion: { _ in
                self.closeButton?.isHidden = true
            }
        }
    }
    
    public func showBackButtonOnVideoComplete() {
        DispatchQueue.main.async {
            self.backButton.isHidden = false
            self.backButton.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            self.backButton.setTitleColor(.white, for: .normal)
            self.backButton.layer.cornerRadius = 20
            self.backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            self.backButton.layer.shadowColor = UIColor.black.cgColor
            self.backButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            self.backButton.layer.shadowRadius = 4
            self.backButton.layer.shadowOpacity = 0.3
            
            self.view.bringSubviewToFront(self.backButton)
        }
    }
    
    public func setVideoPlayingState(_ isPlaying: Bool) {
        DispatchQueue.main.async {
            self.isVideoPlaying = isPlaying
            print("🔍 AdViewController: Video playing state set to: \(isPlaying)")
        }
    }
    
    public func enableSwipeGestures() {
        DispatchQueue.main.async {
            self.swipeGestureRecognizer?.isEnabled = true
            self.doubleTapGestureRecognizer?.isEnabled = true
            print("🔍 AdViewController: Swipe gestures enabled")
        }
    }
    
    public func disableSwipeGestures() {
        DispatchQueue.main.async {
            self.swipeGestureRecognizer?.isEnabled = false
            self.doubleTapGestureRecognizer?.isEnabled = false
            print("🔍 AdViewController: Swipe gestures disabled")
        }
    }
}

public extension AdViewController {
    
    static func presentAd(placementId: String,
                          adType: AdType,
                          from viewController: UIViewController,
                          callback: AdCallback? = nil) {
        let adViewController = AdViewController(placementId: placementId,
                                                adType: adType,
                                                callback: callback)
        adViewController.modalPresentationStyle = .fullScreen
        viewController.present(adViewController, animated: true)
    }
    
    static func pushAd(placementId: String,
                       adType: AdType,
                       onto navigationController: UINavigationController,
                       callback: AdCallback? = nil) {
        let adViewController = AdViewController(placementId: placementId,
                                                adType: adType,
                                                callback: callback)
        navigationController.pushViewController(adViewController, animated: true)
    }
}

