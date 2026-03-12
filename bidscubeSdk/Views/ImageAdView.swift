import UIKit
import WebKit
import bidscubeSdk

public final class ImageAdView: UIView {
    private let webView = WKWebView()
    private let loadingLabel = UILabel()
    private var clickURL: String?
    private var placementId: String = ""
    private weak var callback: AdCallback?
    
    public init() {
        super.init(frame: .zero)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .lightGray
        
        loadingLabel.text = "Loading Ad..."
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = .white
        loadingLabel.backgroundColor = .black.withAlphaComponent(0.7)
        loadingLabel.layer.cornerRadius = 4
        loadingLabel.clipsToBounds = true
        
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.isUserInteractionEnabled = true
        
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
            loadingLabel.widthAnchor.constraint(equalToConstant: 120),
            loadingLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        isUserInteractionEnabled = true
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)
    }
    
    public func loadAdContent(_ htmlContent: String) {
        loadingLabel.isHidden = false
        extractClickURLFromHTML(htmlContent)
        
        let cleanHTML = htmlContent
            .replacingOccurrences(of: "document.write(", with: "")
            .replacingOccurrences(of: ");", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let fullHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 0; overflow: hidden; }
                * { box-sizing: border-box; }
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
    
    public func setPlacementInfo(_ placementId: String, callback: AdCallback?) {
        self.placementId = placementId
        self.callback = callback
    }
    
    public func loadAdFromURL(_ url: URL) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading Ad..."
        
        print("ImageAdView: Making HTTP request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceInfo.userAgent, forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.loadingLabel.text = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let htmlContent = String(data: data, encoding: .utf8) else {
                    self.loadingLabel.text = "Error: Invalid response"
                    return
                }
                
                do {
                    if let jsonData = htmlContent.data(using: .utf8),
                       let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let adm = json["adm"] as? String {
                         print("Adm: \(adm)")
                        
                        if let positionValue = json["position"] as? Int,
                           let position = bidscubeSdk.AdPosition(rawValue: positionValue) {
                            print("ImageAdView: Received position from server: \(positionValue) - \(self.displayName(for: position))")
                            DispatchQueue.main.async {
                                BidscubeSDK.setResponseAdPosition(position)
                            }
                        }
                        
                        if let skadnetworkData = json["skadnetwork"] as? [String: Any] {
                            print("ImageAdView: Found SKAdNetwork data in response")
                            if let skadnetworkResponse = SKAdNetworkManager.parseSKAdNetworkResponse(from: skadnetworkData) {
                                print("ImageAdView: Successfully parsed SKAdNetwork response")
                                SKAdNetworkManager.processSKAdNetworkResponse(skadnetworkResponse)
                            } else {
                                print("ImageAdView: Failed to parse SKAdNetwork response")
                            }
                        } else {
                            print("ImageAdView: No SKAdNetwork data in response")
                        }
                        
                        self.loadAdContent(adm)
                    } else {
                        self.loadAdContent(htmlContent)
                    }
                } catch {
                    self.loadAdContent(htmlContent)
                }
            }
        }.resume()
    }
    
    private func displayName(for position: bidscubeSdk.AdPosition) -> String {
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
                            print("ImageAdView: Extracted click URL from HTML: \(decodedURL)")
                            return
                        }
                    }
                }
            }
        }
        
        print("ImageAdView: Could not extract click URL from HTML content")
    }
    
    @objc private func handleTap() {
        print("ImageAdView: Tap gesture detected")
        callback?.onAdClicked(placementId)
        if let clickURL = clickURL, let url = URL(string: clickURL) {
            print("ImageAdView: Opening extracted click URL: \(clickURL)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("ImageAdView: No click URL available to open")
        }
    }
    
}

extension ImageAdView: WKNavigationDelegate {
    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        print("ImageAdView: Navigation request to: \(url.absoluteString)")
        print("ImageAdView: Navigation type: \(navigationAction.navigationType.rawValue)")

        guard navigationAction.navigationType == .linkActivated else {
            print("ImageAdView: Non-user navigation, allowing")
            decisionHandler(.allow)
            return
        }

        if url.absoluteString.contains("clck") || url.absoluteString.contains("click") {
            print("ImageAdView: Detected click tracking, triggering callback")
            callback?.onAdClicked(placementId)

            decisionHandler(.allow)
            return
        }

        if url.scheme?.hasPrefix("http") == true {
            print("ImageAdView: Opening external URL: \(url.absoluteString)")
            callback?.onAdClicked(placementId)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

extension ImageAdView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
