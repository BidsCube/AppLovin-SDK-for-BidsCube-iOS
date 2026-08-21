import Testing
import UIKit
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

/// Documents the SmokeWindowDiagnostics weak-label crash class without importing the test harness module.
struct SmokeWindowDiagnosticsLogicTests {
    @Test @MainActor func weakLabelReferenceWithoutStrongOwnerIsNil() {
        weak var weakLabel: UILabel?
        weakLabel = UILabel()
        #expect(weakLabel == nil, "UILabel must be retained by a stack/superview before weak handle is valid")
    }

    @Test @MainActor func labelRetainedByStackKeepsWeakHandleAlive() {
        weak var weakLabel: UILabel?
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let label = UILabel()
        weakLabel = label
        let stack = UIStackView(arrangedSubviews: [label])
        host.addSubview(stack)
        #expect(weakLabel != nil)
    }
}
