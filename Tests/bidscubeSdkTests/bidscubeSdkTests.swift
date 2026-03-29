import Testing
import UIKit
@testable import BidscubeSDK

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

    @Test func normalizesAdRequestAuthority() {
        #expect(URLBuilder.normalizedAdRequestAuthority(from: nil) == DeviceInfo.defaultAdRequestAuthority)
        #expect(URLBuilder.normalizedAdRequestAuthority(from: "   ") == DeviceInfo.defaultAdRequestAuthority)
        #expect(URLBuilder.normalizedAdRequestAuthority(from: "https://example.com/sdk?x=1") == "example.com")
        #expect(URLBuilder.normalizedAdRequestAuthority(from: "http://127.0.0.1:8787/path") == "127.0.0.1:8787")
        #expect(URLBuilder.normalizedAdRequestAuthority(from: "https%3A%2F%2Fexample.com%2Fsdk%3Fa%3D1") == "example.com")
    }

    @Test func buildsImageRequestURLUsingHttpsAndSdkPath() throws {
        let url = try #require(
            URLBuilder.buildAdRequestURL(
                base: "127.0.0.1:8787",
                placementId: "20212",
                adType: .image,
                position: .unknown,
                timeoutMs: 1_000,
                debug: false,
                includeSKAdNetworks: false
            )
        )

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(components.scheme == "https")
        #expect(components.host == "127.0.0.1")
        #expect(components.port == 8787)
        #expect(components.path == "/sdk")
        #expect(query["placementId"] == "20212")
        #expect(query["c"] == "b")
        #expect(query["m"] == "api")
        #expect(query["res"] == "js")
        #expect(query["app"] == "1")
    }

    @Test func buildsNativeRequestURLWithLogicalDimensions() throws {
        let url = try #require(
            URLBuilder.buildAdRequestURL(
                base: "ssp-bcc-ads.com",
                placementId: "20214",
                adType: .native,
                position: .unknown,
                timeoutMs: 1_000,
                debug: false,
                includeSKAdNetworks: false,
                nativeWidth: 320,
                nativeHeight: 50
            )
        )

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(components.scheme == "https")
        #expect(components.path == "/sdk")
        #expect(query["c"] == "n")
        #expect(query["m"] == "s")
        #expect(query["id"] == "20214")
        #expect(query["w"] == "320")
        #expect(query["h"] == "50")
        #expect(query["gdpr"] != nil)
        #expect(query["gdpr_consent"] != nil)
        #expect(query["us_privacy"] != nil)
        #expect(query["ccpa"] != nil)
        #expect(query["coppa"] != nil)
    }
}
