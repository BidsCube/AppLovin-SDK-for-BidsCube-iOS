import XCTest
@testable import BidscubeSDKAppLovin

final class BidscubeMAXAdViewTests: XCTestCase {
    func testAdRequestTimeoutMatchesAndroidHttpProvider() {
        XCTAssertEqual(Constants.adRequestTimeoutMs, 10_000)
    }

    func testImageAdLoggingDuplicatesToMaxAdapterTag() {
        Logger.configureLogging(enableLogging: true, enableDebugMode: false)
        Logger.imageAd("test-image-ad-log")
        // Smoke: no crash; publishers filter console by BidscubeMAX for this line.
    }
}
