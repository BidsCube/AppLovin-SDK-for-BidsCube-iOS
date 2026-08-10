import XCTest
@testable import BidscubeSDKAppLovin

final class BidscubeMAXPlacementTests: XCTestCase {
    func testPrefersThirdPartyPlacementIdOverServerAppId() {
        XCTAssertEqual(
            resolveBidscubePlacementId(thirdPartyPlacementId: "21978", serverAppId: "publisher-init-app-id"),
            "21978"
        )
    }

    func testUsesThirdPartyPlacementIdWhenServerAppIdMissing() {
        XCTAssertEqual(
            resolveBidscubePlacementId(thirdPartyPlacementId: "21488", serverAppId: nil),
            "21488"
        )
    }

    func testFallsBackToServerAppIdOnlyWhenPlacementIdEmpty() {
        XCTAssertEqual(
            resolveBidscubePlacementId(thirdPartyPlacementId: "", serverAppId: "legacy-only"),
            "legacy-only"
        )
    }

    func testTrimsWhitespaceFromPlacementId() {
        XCTAssertEqual(
            resolveBidscubePlacementId(thirdPartyPlacementId: "  21980  ", serverAppId: "init-id"),
            "21980"
        )
    }
}
