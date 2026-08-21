import UIKit
import WebKit

final class CompanionEndCardView: UIView {
    private let companion: CompanionAd
    private let placementId: String
    private weak var callback: AdCallback?
    private let clickHandler: CompanionClickHandler
    private let onRequestClose: () -> Void

    private var imageView: UIImageView?
    private var webView: WKWebView?
    private var navigationChrome: FullscreenVideoChromeControls?

    init(
        companion: CompanionAd,
        placementId: String,
        callback: AdCallback?,
        onRequestClose: @escaping () -> Void
    ) {
        self.companion = companion
        self.placementId = placementId
        self.callback = callback
        self.clickHandler = CompanionClickHandler(companionAd: companion)
        self.onRequestClose = onRequestClose
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .black
        translatesAutoresizingMaskIntoConstraints = false

        switch companion.resourceType {
        case .static:
            setupStaticImage()
        case .html:
            setupHtml()
        case .iframe:
            setupIFrame()
        }

        setupNavigationChrome()
        clickHandler.fireCreativeViewOnce()
    }

    private func setupStaticImage() {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.imageView = imageView

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        imageView.addGestureRecognizer(tap)

        guard let url = URL(string: companion.resource) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }

    private func setupHtml() {
        let webView = makeWebView()
        webView.loadHTMLString(companion.resource, baseURL: nil)
        self.webView = webView
    }

    private func setupIFrame() {
        let webView = makeWebView()
        if let url = URL(string: companion.resource) {
            webView.load(URLRequest(url: url))
        }
        self.webView = webView
    }

    private func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        return webView
    }

    private func setupNavigationChrome() {
        let chrome = FullscreenVideoChromeControls(
            target: self,
            backAction: #selector(closeTapped),
            closeAction: #selector(closeTapped)
        )
        chrome.install(in: self)
        chrome.show(animated: false)
        navigationChrome = chrome
    }

    @objc private func handleTap() {
        clickHandler.handleClick(placementId: placementId, callback: callback)
    }

    @objc private func closeTapped() {
        onRequestClose()
    }

    func destroy() {
        webView?.navigationDelegate = nil
        webView?.removeFromSuperview()
        imageView?.removeFromSuperview()
        removeFromSuperview()
    }
}

extension CompanionEndCardView: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if clickHandler.handleExternalNavigation(url, placementId: placementId, callback: callback) {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
