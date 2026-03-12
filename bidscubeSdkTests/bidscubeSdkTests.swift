import Testing
import UIKit
@testable import bidscubeSdk

struct bidscubeSdkTests {
    final class Delegate: AdCallback, ConsentCallback {
        var consentInfoUpdated = false
        var adLoaded = false

        func onAdLoading(_ placementId: String) {}
        func onAdLoaded(_ placementId: String) { adLoaded = true }
        func onAdDisplayed(_ placementId: String) {}
        func onAdClicked(_ placementId: String) {}
        func onAdClosed(_ placementId: String) {}
        func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {}

        func onConsentInfoUpdated() { consentInfoUpdated = true }
        func onConsentInfoUpdateFailed(_ error: Error) {}
        func onConsentFormShown() {}
        func onConsentFormError(_ error: Error) {}
        func onConsentGranted() {}
        func onConsentDenied() {}
        func onConsentNotRequired() {}
        func onConsentStatusChanged(_ hasConsent: Bool) {}
    }

    @Test func initializeAndShow() async throws {
        let config = SDKConfig.Builder()
            .enableLogging(true)
            .enableDebugMode(true)
            .defaultAdTimeout(1_000)
            .defaultAdPosition(.unknown)
            .build()

        BidscubeSDK.initialize(config: config)
        #expect(BidscubeSDK.isInitialized())

        let delegate = Delegate()
        BidscubeSDK.requestConsentInfoUpdate(callback: delegate)
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(delegate.consentInfoUpdated)

        BidscubeSDK.showImageAd("20212", delegate)
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(delegate.adLoaded)

        let v1 = BidscubeSDK.getImageAdView("20212", delegate)
        #expect((v1 as UIView?) != nil)
        let v2 = BidscubeSDK.getVideoAdView("20213", delegate)
        #expect((v2 as UIView?) != nil)
        let v3 = BidscubeSDK.getNativeAdView("20214", delegate)
        #expect((v3 as UIView?) != nil)

        BidscubeSDK.cleanup()
        #expect(!BidscubeSDK.isInitialized())
    }
}
