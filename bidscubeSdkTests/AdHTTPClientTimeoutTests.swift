import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

@Suite struct AdHTTPClientTimeoutTests {
    @Test func maxAdapterTimeoutIsEightSeconds() {
        #expect(Constants.maxAdapterAdRequestTimeoutMs == 8_000)
        #expect(Constants.adRequestTimeoutMs == 10_000)
        #expect(Constants.maxAdapterAdRequestTimeoutMs < Constants.adRequestTimeoutMs)
    }

    @Test func imageAdViewLoadUsesProvidedTimeout() async {
        await MainActor.run {
            AdHTTPClient.lastRequestTimeoutMsForTesting = nil
            let view = ImageAdView()
            view.setPlacementInfo("20212", callback: nil)
            view.loadAdFromURL(URL(string: "https://example.com/ad")!, timeoutMs: 8_000)
            #expect(AdHTTPClient.lastRequestTimeoutMsForTesting == 8_000)
        }
    }

    @Test func bannerAdViewLoadUsesProvidedTimeout() async {
        await MainActor.run {
            AdHTTPClient.lastRequestTimeoutMsForTesting = nil
            let view = BannerAdView(position: .header)
            view.setPlacementInfo("20212", callback: nil)
            view.loadAdFromURL(URL(string: "https://example.com/ad")!, timeoutMs: 8_000)
            #expect(AdHTTPClient.lastRequestTimeoutMsForTesting == 8_000)
        }
    }

    @Test func lateImageCallbackSuppressedAfterNewLoad() async {
        await MainActor.run {
            let view = ImageAdView()
            view.setPlacementInfo("20212", callback: nil)
            view.loadAdFromURL(URL(string: "https://example.com/ad1")!, timeoutMs: 8_000)
            view.loadAdFromURL(URL(string: "https://example.com/ad2")!, timeoutMs: 8_000)
            #expect(AdHTTPClient.lastRequestTimeoutMsForTesting == 8_000)
        }
    }
}
