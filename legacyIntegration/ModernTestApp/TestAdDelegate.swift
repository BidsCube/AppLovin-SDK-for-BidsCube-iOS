import BidscubeSDK
import Foundation

final class TestAdDelegate: AdCallback {
    private let label: String

    init(label: String) {
        self.label = label
    }

    private func log(_ event: String, placementId: String, extra: String = "") {
        let suffix = extra.isEmpty ? "" : " \(extra)"
        TestLog.append("[\(label)] \(event) placement=\(placementId)\(suffix)")
    }

    func onAdLoading(_ placementId: String) { log("loading", placementId: placementId) }
    func onAdLoaded(_ placementId: String) { log("loaded", placementId: placementId) }
    func onAdDisplayed(_ placementId: String) { log("displayed", placementId: placementId) }
    func onAdClicked(_ placementId: String) { log("clicked", placementId: placementId) }
    func onAdClosed(_ placementId: String) { log("closed", placementId: placementId) }
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        log("failed", placementId: placementId, extra: "code=\(errorCode) msg=\(errorMessage)")
    }
    func onVideoAdStarted(_ placementId: String) { log("videoStarted", placementId: placementId) }
    func onVideoAdCompleted(_ placementId: String) { log("videoCompleted", placementId: placementId) }
    func onVideoAdSkipped(_ placementId: String) { log("videoSkipped", placementId: placementId) }
    func onVideoAdSkippable(_ placementId: String) { log("videoSkippable", placementId: placementId) }
}
