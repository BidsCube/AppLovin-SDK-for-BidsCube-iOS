import UIKit

#if BIDSCUBE_LEGACY_VIDEO
typealias BidscubeDefaultVideoHandler = LegacyVideoAdHandler
#else
typealias BidscubeDefaultVideoHandler = IMAVideoAdHandler
#endif

extension VideoAdView {
    var activeVideoHandler: BidscubeDefaultVideoHandler? {
        get { videoHandlerStorage as? BidscubeDefaultVideoHandler }
        set { videoHandlerStorage = newValue }
    }

    func attachDefaultVideoHandler(_ handler: BidscubeDefaultVideoHandler) {
        handler.setPlacementInfo(placementId, callback: callback)
        handler.setParentViewController(parentViewController)
        addSubview(handler)
        handler.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            handler.topAnchor.constraint(equalTo: topAnchor),
            handler.leadingAnchor.constraint(equalTo: leadingAnchor),
            handler.trailingAnchor.constraint(equalTo: trailingAnchor),
            handler.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        handler.layoutIfNeeded()
        activeVideoHandler = handler
    }

    func startDefaultVideoLoad(vastXML: String? = nil, vastURL: String? = nil) {
        #if BIDSCUBE_LEGACY_VIDEO
        let handler = LegacyVideoAdHandler()
        attachDefaultVideoHandler(handler)
        if let vastXML {
            handler.loadVAST(source: vastXML, isURL: false, clickURL: clickURL)
        } else if let vastURL {
            handler.loadVAST(source: vastURL, isURL: true, clickURL: clickURL)
        }
        #else
        if let vastXML {
            let handler = IMAVideoAdHandler(vastXML: vastXML, clickURL: clickURL)
            attachDefaultVideoHandler(handler)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { handler.loadAd() }
        } else if let vastURL {
            let handler = IMAVideoAdHandler(vastURL: vastURL, clickURL: clickURL)
            attachDefaultVideoHandler(handler)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { handler.loadAd() }
        }
        #endif
        webView.isHidden = true
    }

    func cleanupVideoHandler() {
        #if BIDSCUBE_LEGACY_VIDEO
        (activeVideoHandler as? LegacyVideoAdHandler)?.cleanup()
        #else
        (activeVideoHandler as? IMAVideoAdHandler)?.cleanup()
        #endif
        activeVideoHandler?.removeFromSuperview()
        activeVideoHandler = nil
    }

    func refreshVideoHandlerLayout() {
        #if BIDSCUBE_LEGACY_VIDEO
        activeVideoHandler?.layoutSubviews()
        #else
        (activeVideoHandler as? IMAVideoAdHandler)?.refreshIMASetup()
        activeVideoHandler?.layoutSubviews()
        #endif
    }
}
