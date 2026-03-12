import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

public class IMAViewController: UIViewController {
    
    private var imaVideoHandler: IMAVideoAdHandler?
    private var placementId: String = ""
    private weak var callback: AdCallback?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
    
    public func setupIMAHandler(vastXML: String, placementId: String, callback: AdCallback?) {
        self.placementId = placementId
        self.callback = callback
        
        imaVideoHandler = IMAVideoAdHandler(vastXML: vastXML, clickURL: nil)
        imaVideoHandler?.setPlacementInfo(placementId, callback: callback)
        
        if let handler = imaVideoHandler {
            view.addSubview(handler)
            handler.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                handler.topAnchor.constraint(equalTo: view.topAnchor),
                handler.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                handler.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                handler.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        imaVideoHandler?.loadAd()
    }
    
    public func setupIMAHandler(vastURL: String, placementId: String, callback: AdCallback?) {
        self.placementId = placementId
        self.callback = callback
        
        imaVideoHandler = IMAVideoAdHandler(vastURL: vastURL, clickURL: nil)
        imaVideoHandler?.setPlacementInfo(placementId, callback: callback)
        
        if let handler = imaVideoHandler {
            view.addSubview(handler)
            handler.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                handler.topAnchor.constraint(equalTo: view.topAnchor),
                handler.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                handler.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                handler.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        imaVideoHandler?.loadAd()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imaVideoHandler?.layoutSubviews()
    }
    
    deinit {
        print(" IMAViewController: Deallocated")
    }
}

#if canImport(SwiftUI)
import SwiftUI

public struct IMAVideoAdView: UIViewControllerRepresentable {
    let vastXML: String?
    let vastURL: String?
    let placementId: String
    let callback: AdCallback?
    
    public init(vastXML: String, placementId: String, callback: AdCallback? = nil) {
        self.vastXML = vastXML
        self.vastURL = nil
        self.placementId = placementId
        self.callback = callback
    }
    
    public init(vastURL: String, placementId: String, callback: AdCallback? = nil) {
        self.vastXML = nil
        self.vastURL = vastURL
        self.placementId = placementId
        self.callback = callback
    }
    
    public func makeUIViewController(context: Context) -> IMAViewController {
        let vc = IMAViewController()
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: IMAViewController, context: Context) {
        if let vastXML = vastXML {
            uiViewController.setupIMAHandler(
                vastXML: vastXML,
                placementId: placementId,
                callback: callback
            )
        } else if let vastURL = vastURL {
            uiViewController.setupIMAHandler(
                vastURL: vastURL,
                placementId: placementId,
                callback: callback
            )
        }
    }
}

public struct AdViewControllerView: UIViewControllerRepresentable {
    let placementId: String
    let adType: AdType
    let callback: AdCallback?
    
    public init(placementId: String, adType: AdType, callback: AdCallback? = nil) {
        self.placementId = placementId
        self.adType = adType
        self.callback = callback
    }
    
    public func makeUIViewController(context: Context) -> AdViewController {
        AdViewController(placementId: placementId, adType: adType, callback: callback)
    }
    
    public func updateUIViewController(_ uiViewController: AdViewController, context: Context) {
    }
}
#endif
