#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
public extension BidscubeSDK {
    
    static func getIMAVideoAdView(_ placementId: String, _ callback: AdCallback?) -> some View {
        print("📱 BidscubeSDK: getIMAVideoAdView called for placement: \(placementId)")
        
        callback?.onAdLoading(placementId)
        
        guard let url = buildRequestURL(placementId: placementId, adType: .video) else {
            print("Error: BidscubeSDK: Failed to build request URL for video ad")
            callback?.onAdFailed(placementId, errorCode: -1, errorMessage: "Failed to build request URL")
            return AnyView(Text("Failed to load ad"))
        }
        
        print("🔍 BidscubeSDK: Making video ad request to: \(url.absoluteString)")
        
        return AnyView(
            IMAVideoAdView(
                vastXML: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><VAST version=\"3.0\"><Ad id=\"placeholder\"><InLine><AdSystem>Placeholder</AdSystem><AdTitle>Loading...</AdTitle></InLine></Ad></VAST>",
                placementId: placementId,
                callback: callback
            )
        )
    }
    
    static func getAdViewControllerView(_ placementId: String, adType: AdType, _ callback: AdCallback?) -> some View {
        print("📱 BidscubeSDK: getAdViewControllerView called for placement: \(placementId)")
        
        return AnyView(
            AdViewControllerView(
                placementId: placementId,
                adType: adType,
                callback: callback
            )
        )
    }
}
#endif
