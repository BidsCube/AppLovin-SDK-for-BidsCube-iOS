import UIKit
import AVFoundation
import WebKit

public final class VideoAdView: UIView {
    private let webView = WKWebView()
    private let loadingLabel = UILabel()
    private var imaVideoHandler: IMAVideoAdHandler?
    private var placementId: String = ""
    private weak var callback: AdCallback?
    private weak var parentViewController: UIViewController?
    private var clickURL: String?

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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAdClick))
        addGestureRecognizer(tapGesture)
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
        imaVideoHandler?.cleanup()
        imaVideoHandler = nil
    }
    
    public func refreshIMASetup() {
        imaVideoHandler?.refreshIMASetup()
    }
    
    deinit {
        cleanup()
    }
    
    public func loadVASTContent(_ vastXML: String, clickURL: String? = nil) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading VAST Ad..."
        
        self.clickURL = clickURL
        
        cleanup()
        
        imaVideoHandler = IMAVideoAdHandler(vastXML: vastXML, clickURL: clickURL)
        imaVideoHandler?.setPlacementInfo(placementId, callback: callback)
        imaVideoHandler?.setParentViewController(parentViewController)
        
        if let handler = imaVideoHandler {
            addSubview(handler)
            handler.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                handler.topAnchor.constraint(equalTo: topAnchor),
                handler.leadingAnchor.constraint(equalTo: leadingAnchor),
                handler.trailingAnchor.constraint(equalTo: trailingAnchor),
                handler.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            
            handler.layoutIfNeeded()
        }
        
        webView.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.imaVideoHandler?.loadAd()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadingLabel.isHidden = true
        }
        
        print(" VideoAdView: Loading VAST XML content with IMA SDK")
        print("⚠️ VideoAdView: For SwiftUI apps, consider using IMAVideoAdView instead for better view controller hierarchy")
    }
    
    public func loadVASTFromURL(_ vastURL: String, clickURL: String? = nil) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading VAST Ad..."
        
        self.clickURL = clickURL
        
        cleanup()
        
        imaVideoHandler = IMAVideoAdHandler(vastURL: vastURL, clickURL: clickURL)
        imaVideoHandler?.setPlacementInfo(placementId, callback: callback)
        imaVideoHandler?.setParentViewController(parentViewController)
        
        if let handler = imaVideoHandler {
            addSubview(handler)
            handler.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                handler.topAnchor.constraint(equalTo: topAnchor),
                handler.leadingAnchor.constraint(equalTo: leadingAnchor),
                handler.trailingAnchor.constraint(equalTo: trailingAnchor),
                handler.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            
            handler.layoutIfNeeded()
        }
        
        webView.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.imaVideoHandler?.loadAd()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadingLabel.isHidden = true
        }
    }
    
    public func loadVideoAdFromURL(_ url: URL) {
        loadingLabel.isHidden = false
        loadingLabel.text = "Loading Video Ad..."
        
        print("🔍 VideoAdView: Making HTTP request to: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.loadingLabel.text = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let content = String(data: data, encoding: .utf8) else {
                    self.loadingLabel.text = "Error: Invalid response"
                    return
                }
                
                do {
                    if let jsonData = content.data(using: .utf8),
                       let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let adm = json["adm"] as? String {
                        
                        if let positionValue = json["position"] as? Int,
                           let position = bidscubeSdk.AdPosition(rawValue: positionValue) {
                            print("🔍 VideoAdView: Received position from server: \(positionValue) - \(self.displayName(for: position))")
                            DispatchQueue.main.async {
                                BidscubeSDK.setResponseAdPosition(position)
                            }
                        }
                        
                        if adm.hasPrefix("http") {
                            self.loadVASTFromURL(adm)
                        } else {
                            self.loadVASTContent(adm)
                        }
                    } else {
                        self.loadVASTContent(content)
                    }
                } catch {
                    self.loadVASTContent(content)
                }
            }
        }.resume()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        print("🔍 VideoAdView: layoutSubviews - frame: \(frame)")
        imaVideoHandler?.layoutSubviews()
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
