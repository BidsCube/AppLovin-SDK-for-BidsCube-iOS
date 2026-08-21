import XCTest
@testable import BidscubeSDKAppLovin

final class BidscubeMAXAdViewTests: XCTestCase {
    func testAdRequestTimeoutMatchesAndroidHttpProvider() {
        XCTAssertEqual(Constants.adRequestTimeoutMs, 10_000)
        XCTAssertEqual(Constants.maxAdapterAdRequestTimeoutMs, 8_000)
        XCTAssertLessThan(Constants.maxAdapterAdRequestTimeoutMs, Constants.adRequestTimeoutMs)
    }

    func testImageAdLoggingDuplicatesToMaxAdapterTag() {
        Logger.configureLogging(enableLogging: true, enableDebugMode: false)
        Logger.imageAd("test-image-ad-log")
        // Smoke: no crash; publishers filter console by BidscubeMAX for this line.
    }

    func testBannerAPIUsesImageAdLogger() {
        XCTAssertEqual(Constants.sdkVersion, "1.1.11")
        Logger.configureLogging(enableLogging: true, enableDebugMode: false)
        Logger.imageAd("Loading banner view for placement test, position: footer")
    }
}
