#if canImport(SwiftUI)
import SwiftUI

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
