import XCTest
@testable import BidscubeSDKAppLovin

final class URLBuilderSKAdNetworkTests: XCTestCase {
    override func tearDown() {
        BidscubeSDK.cleanup()
        super.tearDown()
    }

    func testVideoRequestOmitsSKAdNetworkQueryItemsWhenDisabled() {
        let url = URLBuilder.buildAdRequestURL(
            base: "https://ssp-bcc-ads.com/sdk",
            placementId: "21978",
            adType: .video,
            position: .fullScreen,
            timeoutMs: 30_000,
            debug: false,
            includeSKAdNetworks: false
        )

        XCTAssertNotNil(url)
        let query = url?.absoluteString ?? ""
        XCTAssertFalse(query.contains("skadnet="), "SKAdNetwork IDs must not be appended when disabled")
        XCTAssertTrue(query.contains("id=21978"))
    }

    func testBannerRequestOmitsSKAdNetworkQueryItemsByDefault() {
        let url = URLBuilder.buildAdRequestURL(
            base: "https://ssp-bcc-ads.com/sdk",
            placementId: "21980",
            adType: .image,
            position: .footer,
            timeoutMs: 30_000,
            debug: false
        )

        XCTAssertNotNil(url)
        let query = url?.absoluteString ?? ""
        XCTAssertFalse(query.contains("skadnet="))
        XCTAssertTrue(query.contains("placementId=21980"))
    }

    func testVideoRequestStaysCompactEnoughForTypicalNginxLimit() {
        let url = URLBuilder.buildAdRequestURL(
            base: "https://ssp-bcc-ads.com/sdk",
            placementId: "21978",
            adType: .video,
            position: .fullScreen,
            timeoutMs: 30_000,
            debug: false,
            includeSKAdNetworks: false
        )

        XCTAssertNotNil(url)
        XCTAssertLessThan((url?.absoluteString.count ?? Int.max), 2_048)
    }

    func testBuildRequestURLRespectsSDKConfigEnableSKAdNetworkFalse() {
        let config = SDKConfig.Builder()
            .enableSKAdNetwork(false)
            .enableLogging(false)
            .build()

        BidscubeSDK.initialize(config: config)

        let url = BidscubeSDK.buildRequestURL(placementId: "21978", adType: .video)

        XCTAssertNotNil(url)
        XCTAssertFalse(url?.absoluteString.contains("skadnet=") ?? true)
        XCTAssertTrue(url?.absoluteString.contains("id=21978") ?? false)
    }

    func testBuildRequestURLMatchesMAXAdapterInitialization() {
        let config = SDKConfig.Builder()
            .enableLogging(false)
            .enableDebugMode(false)
            .defaultAdTimeout(Constants.defaultTimeoutMs)
            .defaultAdPosition(.fullScreen)
            .enableSKAdNetwork(false)
            .build()

        BidscubeSDK.initialize(config: config)

        let url = BidscubeSDK.buildRequestURL(placementId: "21488", adType: .video)

        XCTAssertNotNil(url)
        XCTAssertFalse(url?.absoluteString.contains("skadnet=") ?? true)
        XCTAssertLessThan((url?.absoluteString.count ?? Int.max), 2_048)
    }
}
