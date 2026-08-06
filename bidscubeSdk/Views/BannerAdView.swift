import UIKit
import WebKit

public final class BannerAdView: UIView {
    private let webView = WKWebView()
    private let loadingLabel = UILabel()
    private var clickURL: String?
    private var placementId: String = ""
    private weak var callback: AdCallback?
    private var didReportLoaded = false
    private var bannerPosition: AdPosition = .header
    private var bannerHeight: CGFloat = 50
    private var bannerWidth: CGFloat = 320
    private var cornerRadius: CGFloat = 0
    
    
    private var isAttachedToScreen = false
    private var parentViewController: UIViewController?
    
    public init(position: AdPosition = .header, cornerRadius: CGFloat = 0) {
        self.bannerPosition = position
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        setupBannerView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBannerView()
    }
    
    private func setupBannerView() {
        
        switch bannerPosition {
        case .header, .footer:
            bannerHeight = 50
            bannerWidth = UIScreen.main.bounds.width
        case .sidebar:
            bannerHeight = 250
            bannerWidth = 120
        default:
            bannerHeight = 50
            bannerWidth = 320
        }
        
        backgroundColor = .clear
        layer.cornerRadius = cornerRadius
        clipsToBounds = cornerRadius > 0
        
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        
        setupLoadingLabel()
        setupWebView()
        setupConstraints()
        
        isUserInteractionEnabled = true
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    private func setupLoadingLabel() {
        loadingLabel.text = "Loading Banner..."
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = .white
        loadingLabel.backgroundColor = .black.withAlphaComponent(0.7)
        loadingLabel.layer.cornerRadius = 4
        loadingLabel.clipsToBounds = true
        loadingLabel.font = UIFont.systemFont(ofSize: 12)
    }
    
    private func setupWebView() {
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.isUserInteractionEnabled = true
    }
    
    private func setupConstraints() {
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
            loadingLabel.widthAnchor.constraint(equalToConstant: 100),
            loadingLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    public func setPlacementInfo(_ placementId: String, callback: AdCallback?) {
        self.placementId = placementId
        self.callback = callback
    }
    
    public func loadAdFromURL(_ url: URL) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading Banner..."
        didReportLoaded = false

        AdHTTPClient.fetchBody(url: url) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.loadingLabel.text = AdErrorCode.message(for: error)
                AdFailureDispatcher.deliver(
                    placementId: self.placementId,
                    format: "banner",
                    callback: self.callback,
                    error: error
                )
            case .success(let body):
                self.handleAdResponseBody(body)
            }
        }
    }

    private func handleAdResponseBody(_ body: String) {
        applyResponseMetadata(from: body)

        guard let markup = BannerAdMarkupNormalizer.extractRenderableMarkup(from: body) else {
            AdFailureDispatcher.deliver(
                placementId: placementId,
                format: "banner",
                callback: callback,
                errorCode: AdErrorCode.invalidResponse,
                errorMessage: "Failed to parse ad server response"
            )
            return
        }

        loadAdContent(markup)
        reportAdLoadedIfNeeded()
    }

    private func applyResponseMetadata(from body: String) {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if let positionValue = json["position"] as? Int,
           let position = AdPosition(rawValue: positionValue) {
            BidscubeSDK.setResponseAdPosition(position)
        }

        if #available(iOS 14.0, *),
           let skadnetworkData = json["skadnetwork"] as? [String: Any],
           let skadnetworkResponse = SKAdNetworkManager.parseSKAdNetworkResponse(from: skadnetworkData) {
            SKAdNetworkManager.processSKAdNetworkResponse(skadnetworkResponse)
        }
    }

    private func reportAdLoadedIfNeeded() {
        guard !didReportLoaded else { return }
        didReportLoaded = true
        callback?.onAdLoaded(placementId)
        callback?.onAdDisplayed(placementId)
    }
    
    public func loadAdContent(_ htmlContent: String) {
        loadingLabel.isHidden = false

        let cleanHTML = BannerAdMarkupNormalizer.normalize(htmlContent)
        extractClickURLFromHTML(cleanHTML)

        let fullHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    overflow: hidden;
                    background: transparent;
                }
                * {
                    box-sizing: border-box;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    display: block;
                }
            </style>
        </head>
        <body>
            \(cleanHTML)
        </body>
        </html>
        """

        webView.loadHTMLString(fullHTML, baseURL: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadingLabel.isHidden = true
        }
    }
    
    
    
    public func attachToScreen(in viewController: UIViewController) {
        guard !isAttachedToScreen else { return }
        
        parentViewController = viewController
        isAttachedToScreen = true
        
        viewController.view.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        
        setupBannerConstraints(in: viewController.view)
        
        
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
        
        print("BannerAdView: Attached to screen at \(bannerPosition)")
    }
    
    public func detachFromScreen() {
        guard isAttachedToScreen else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            self.isAttachedToScreen = false
            self.parentViewController = nil
            
            
            BidscubeSDK.untrackBanner(self)
        }
        
        print("BannerAdView: Detached from screen")
    }
    
    private func setupBannerConstraints(in parentView: UIView) {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: bannerWidth),
            heightAnchor.constraint(equalToConstant: bannerHeight)
        ])
        
        switch bannerPosition {
        case .header:
            NSLayoutConstraint.activate([
                topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor),
                centerXAnchor.constraint(equalTo: parentView.centerXAnchor)
            ])
        case .footer:
            NSLayoutConstraint.activate([
                bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor),
                centerXAnchor.constraint(equalTo: parentView.centerXAnchor)
            ])
        case .sidebar:
            NSLayoutConstraint.activate([
                trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor),
                centerYAnchor.constraint(equalTo: parentView.centerYAnchor)
            ])
        default:
            NSLayoutConstraint.activate([
                centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
                centerYAnchor.constraint(equalTo: parentView.centerYAnchor)
            ])
        }
    }
    
    
    
    public func setBannerDimensions(width: CGFloat, height: CGFloat) {
        bannerWidth = width
        bannerHeight = height
        
        
        if isAttachedToScreen {
            removeFromSuperview()
            if let parentView = parentViewController?.view {
                attachToScreen(in: parentViewController!)
            }
        }
    }
    
    public func setBannerPosition(_ position: AdPosition) {
        bannerPosition = position
        
        
        if isAttachedToScreen {
            removeFromSuperview()
            if let parentView = parentViewController?.view {
                attachToScreen(in: parentViewController!)
            }
        }
    }
    
    public func setCornerRadius(_ radius: CGFloat) {
        cornerRadius = radius
        layer.cornerRadius = cornerRadius
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
    
    private func extractClickURLFromHTML(_ htmlContent: String) {
       let patterns = [
    "https?://[^\"'\\\\s]+",
    "curl=([^&\"'\\\\s]+)"
]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: htmlContent.utf16.count)
                if let match = regex.firstMatch(in: htmlContent, options: [], range: range) {
                    let matchRange = match.range
                    if let swiftRange = Range(matchRange, in: htmlContent) {
                        let extractedURL = String(htmlContent[swiftRange])
                        if let decodedURL = extractedURL.removingPercentEncoding {
                            self.clickURL = decodedURL
                            print("BannerAdView: Extracted click URL from HTML: \(decodedURL)")
                            return
                        }
                    }
                }
            }
        }
        
        print("BannerAdView: Could not extract click URL from HTML content")
    }
    
    @objc private func handleTap() {
        print("BannerAdView: Tap gesture detected")
        callback?.onAdClicked(placementId)
        if let clickURL = clickURL, let url = URL(string: clickURL) {
            print("BannerAdView: Opening extracted click URL: \(clickURL)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("BannerAdView: No click URL available to open")
        }
    }
}



extension BannerAdView: WKNavigationDelegate {
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        print("BannerAdView: Navigation request to: \(url.absoluteString)")
        print("BannerAdView: Navigation type: \(navigationAction.navigationType.rawValue)")

        guard navigationAction.navigationType == .linkActivated else {
            print("BannerAdView: Non-user navigation, allowing")
            decisionHandler(.allow)
            return
        }

        if url.absoluteString.contains("clck") || url.absoluteString.contains("click") {
            print("BannerAdView: Detected click tracking, triggering callback")
            callback?.onAdClicked(placementId)

            decisionHandler(.allow)
            return
        }

        if url.scheme?.hasPrefix("http") == true {
            print("BannerAdView: Opening external URL: \(url.absoluteString)")
            callback?.onAdClicked(placementId)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}



extension BannerAdView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
