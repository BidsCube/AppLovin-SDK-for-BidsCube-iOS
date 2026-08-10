import XCTest
@testable import BidscubeSDKAppLovin

final class BidscubeMAXLoggingTests: XCTestCase {
    func testDefaultsToTestingFlagsWhenServerParamsMissing() {
        let flags = resolveBidscubeLoggingFlags(isTesting: true, serverParameters: [:])
        XCTAssertTrue(flags.enableLogging)
        XCTAssertTrue(flags.enableDebugMode)
    }

    func testDefaultsToOffWhenNotTestingAndNoServerParams() {
        let flags = resolveBidscubeLoggingFlags(isTesting: false, serverParameters: [:])
        XCTAssertFalse(flags.enableLogging)
        XCTAssertFalse(flags.enableDebugMode)
    }

    func testExplicitEnableLoggingOverridesTestingOff() {
        let flags = resolveBidscubeLoggingFlags(
            isTesting: false,
            serverParameters: ["enable_logging": "true"]
        )
        XCTAssertTrue(flags.enableLogging)
        XCTAssertFalse(flags.enableDebugMode)
    }

    func testExplicitDisableDebugOverridesTestingOn() {
        let flags = resolveBidscubeLoggingFlags(
            isTesting: true,
            serverParameters: ["enable_debug_mode": "false"]
        )
        XCTAssertTrue(flags.enableLogging)
        XCTAssertFalse(flags.enableDebugMode)
    }

    func testCamelCaseAndDebugAliasKeys() {
        let flags = resolveBidscubeLoggingFlags(
            isTesting: false,
            serverParameters: [
                "enableLogging": "1",
                "debug": "yes"
            ]
        )
        XCTAssertTrue(flags.enableLogging)
        XCTAssertTrue(flags.enableDebugMode)
    }
}
