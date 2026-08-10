import XCTest
@testable import BidscubeSDKAppLovin

final class BidscubeMAXAdViewTests: XCTestCase {
    func testAdRequestTimeoutMatchesAndroidHttpProvider() {
        XCTAssertEqual(Constants.adRequestTimeoutMs, 10_000)
    }
}
