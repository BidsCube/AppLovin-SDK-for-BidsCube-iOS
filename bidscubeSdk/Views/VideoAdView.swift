import UIKit
import AVFoundation
import WebKit

public final class VideoAdView: UIView {
    let webView = WKWebView()
    private let loadingLabel = UILabel()
    var videoHandlerStorage: UIView?
    private var customVideoPlayerView: (UIView & BidscubeCustomVideoPlayer)?
    var placementId: String = ""
    weak var callback: AdCallback?
    weak var parentViewController: UIViewController?
    private var didReportLoaded = false
    var clickURL: String?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .black
        layer.masksToBounds = true
        layer.cornerRadius = 6
        
        loadingLabel.text = "Loading Video Ad..."
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = .white
        loadingLabel.backgroundColor = .black.withAlphaComponent(0.7)
        loadingLabel.layer.cornerRadius = 4
        loadingLabel.clipsToBounds = true
        
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        addSubview(webView)
        addSubview(loadingLabel)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            loadingLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingLabel.widthAnchor.constraint(equalToConstant: 150),
            loadingLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        #if !BIDSCUBE_LEGACY_VIDEO
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAdClick))
        addGestureRecognizer(tapGesture)
        #endif
        isUserInteractionEnabled = true
        
    }
    

    public func setPlacementInfo(_ placementId: String, callback: AdCallback?) {
        self.placementId = placementId
        self.callback = callback
    }
    
    public func setParentViewController(_ viewController: UIViewController?) {
        self.parentViewController = viewController
        self.parentViewController?.view.layoutIfNeeded()
    }
    
    public func cleanup() {
        customVideoPlayerView?.cleanup()
        customVideoPlayerView?.removeFromSuperview()
        customVideoPlayerView = nil
        cleanupVideoHandler()
    }
    
    public func refreshIMASetup() {
        refreshVideoHandlerLayout()
    }
    
    deinit {
        cleanup()
    }
    
    public func loadVASTContent(_ vastXML: String, clickURL: String? = nil) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading VAST Ad..."
        Logger.player("Video ad request resolved for placement \(placementId). Starting player load from XML payload.")
        
        self.clickURL = clickURL
        
        cleanup()

        if let customPlayer = BidscubeSDK.makeCustomVideoPlayerView() {
            customVideoPlayerView = customPlayer
            customPlayer.setPlacementInfo(placementId, callback: callback)
            customPlayer.setParentViewController(parentViewController)
            addSubview(customPlayer)
            customPlayer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                customPlayer.topAnchor.constraint(equalTo: topAnchor),
                customPlayer.leadingAnchor.constraint(equalTo: leadingAnchor),
                customPlayer.trailingAnchor.constraint(equalTo: trailingAnchor),
                customPlayer.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            Logger.player("Using client custom video player for placement \(placementId)")
            customPlayer.loadVAST(source: vastXML, isURL: false, clickURL: clickURL)
            webView.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.loadingLabel.isHidden = true
            }
            return
        }
        
        startDefaultVideoLoad(vastXML: vastXML)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadingLabel.isHidden = true
        }
        
        #if BIDSCUBE_LEGACY_VIDEO
        Logger.player("Using legacy AVPlayer for placement \(placementId) with inline VAST XML")
        #else
        Logger.player("Using default IMA player for placement \(placementId) with inline VAST XML")
        Logger.warning("For SwiftUI apps, consider using IMAVideoAdView instead for better view controller hierarchy", prefix: Constants.LogPrefixes.player)
        #endif
    }
    
    public func loadVASTFromURL(_ vastURL: String, clickURL: String? = nil) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading VAST Ad..."
        Logger.player("Video ad request resolved for placement \(placementId). Starting player load from URL \(vastURL)")
        
        self.clickURL = clickURL
        
        cleanup()

        if let customPlayer = BidscubeSDK.makeCustomVideoPlayerView() {
            customVideoPlayerView = customPlayer
            customPlayer.setPlacementInfo(placementId, callback: callback)
            customPlayer.setParentViewController(parentViewController)
            addSubview(customPlayer)
            customPlayer.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                customPlayer.topAnchor.constraint(equalTo: topAnchor),
                customPlayer.leadingAnchor.constraint(equalTo: leadingAnchor),
                customPlayer.trailingAnchor.constraint(equalTo: trailingAnchor),
                customPlayer.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            Logger.player("Using client custom video player for placement \(placementId)")
            customPlayer.loadVAST(source: vastURL, isURL: true, clickURL: clickURL)
            webView.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.loadingLabel.isHidden = true
            }
            return
        }
        
        startDefaultVideoLoad(vastURL: vastURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadingLabel.isHidden = true
        }
    }
    
    public func loadAdFromCachedResponseBody(_ body: String) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading Video Ad..."
        didReportLoaded = false
        Logger.videoAd("Loading cached video ad payload for placement \(placementId)")
        handleVideoResponseBody(body)
    }

    public func loadVideoAdFromURL(_ url: URL) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading Video Ad..."
        didReportLoaded = false

        Logger.videoAd("Loading video ad for placement \(placementId)")
        Logger.network("Making SSP request to: \(url.absoluteString)")

        AdHTTPClient.fetchBody(url: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                Logger.error(
                    "Video ad request failed for placement \(self.placementId): \(AdErrorCode.message(for: error))",
                    prefix: Constants.LogPrefixes.videoAd
                )
                self.loadingLabel.text = AdErrorCode.message(for: error)
                AdFailureDispatcher.deliver(
                    placementId: self.placementId,
                    format: "video",
                    callback: self.callback,
                    error: error
                )
            case .success(let content):
                self.handleVideoResponseBody(content)
            }
        }
    }

    private func handleVideoResponseBody(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            AdFailureDispatcher.deliver(
                placementId: placementId,
                format: "video",
                callback: callback,
                errorCode: AdErrorCode.emptyAdm,
                errorMessage: "Empty ad markup"
            )
            return
        }

        if let jsonData = trimmed.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let adm = json["adm"] as? String {
            if adm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AdFailureDispatcher.deliver(
                    placementId: placementId,
                    format: "video",
                    callback: callback,
                    errorCode: AdErrorCode.emptyAdm,
                    errorMessage: "Empty ad markup"
                )
                return
            }

            if let positionValue = json["position"] as? Int,
               let position = AdPosition(rawValue: positionValue) {
                BidscubeSDK.setResponseAdPosition(position)
            }

            if adm.hasPrefix("http") {
                loadVASTFromURL(adm)
            } else {
                loadVASTContent(adm)
            }
            return
        }

        if trimmed.hasPrefix("<") || trimmed.contains("<VAST") {
            loadVASTContent(trimmed)
            return
        }

        AdFailureDispatcher.deliver(
            placementId: placementId,
            format: "video",
            callback: callback,
            errorCode: AdErrorCode.invalidResponse,
            errorMessage: "Failed to parse ad server response"
        )
    }

    private func reportAdLoadedIfNeeded() {
        guard !didReportLoaded else { return }
        didReportLoaded = true
        callback?.onAdLoaded(placementId)
        callback?.onAdDisplayed(placementId)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        refreshVideoHandlerLayout()
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
    
    @objc private func handleAdClick() {
        print("🔍 VideoAdView: Ad clicked for placement: \(placementId)")
        
        callback?.onAdClicked(placementId)
        
        if let clickURL = clickURL, let url = URL(string: clickURL) {
            print("🔍 VideoAdView: Opening URL in browser: \(clickURL)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("⚠️ VideoAdView: No click URL available")
        }
    }
    
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
    
    public func showCloseButton() {
        if let adViewController = parentViewController as? AdViewController {
            adViewController.showCloseButton()
        }
    }
    
    public func showCloseButtonOnComplete() {
        if let adViewController = parentViewController as? AdViewController {
            adViewController.showCloseButtonOnComplete()
        }
    }
    
    public func hideCloseButton() {
        if let adViewController = parentViewController as? AdViewController {
            adViewController.hideCloseButton()
        }
    }
}
