import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

private final class RecordingAdCallback: AdCallback {
    private(set) var events: [String] = []

    func onAdLoading(_ placementId: String) { events.append("loading") }
    func onAdLoaded(_ placementId: String) { events.append("loaded") }
    func onAdDisplayed(_ placementId: String) { events.append("displayed") }
    func onAdClicked(_ placementId: String) { events.append("clicked") }
    func onAdClosed(_ placementId: String) { events.append("closed") }
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) { events.append("failed") }
    func onVideoAdStarted(_ placementId: String) { events.append("started") }
    func onVideoAdCompleted(_ placementId: String) { events.append("completed") }
    func onVideoAdSkipped(_ placementId: String) { events.append("skipped") }
    func onVideoAdSkippable(_ placementId: String) { events.append("skippable") }
}

@Suite(.serialized)
struct AdSessionCoordinatorTests {
    private let placement = "test-placement"

    @Test func successfulLifecycleFiresEachEventOnce() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverLoading(placement, to: callback)
        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverDisplayed(placement, to: callback)
        coordinator.deliverVideoStarted(placement, to: callback)
        coordinator.deliverVideoCompleted(placement, to: callback)
        coordinator.deliverClosed(placement, to: callback)

        #expect(callback.events == ["loading", "loaded", "displayed", "started", "completed", "closed"])
        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverClosed(placement, to: callback)
        #expect(callback.events.count == 6)
    }

    @Test func mediaLoadFailureDoesNotEmitSuccessOrClose() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverLoading(placement, to: callback)
        coordinator.deliverFailed(placement, errorCode: 403, errorMessage: "media", to: callback)

        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverDisplayed(placement, to: callback)
        coordinator.deliverVideoCompleted(placement, to: callback)
        coordinator.deliverClosed(placement, to: callback)

        #expect(callback.events == ["loading", "failed"])
    }

    @Test func duplicateFailureIsIgnored() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverFailed(placement, errorCode: 1, errorMessage: "a", to: callback)
        coordinator.deliverFailed(placement, errorCode: 2, errorMessage: "b", to: callback)

        #expect(callback.events == ["failed"])
    }

    @Test func displayedCannotFireBeforeLoaded() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverDisplayed(placement, to: callback)
        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverDisplayed(placement, to: callback)

        #expect(callback.events == ["loaded", "displayed"])
    }

    @Test func skipPreventsCompleted() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverVideoSkipped(placement, to: callback)
        coordinator.deliverVideoCompleted(placement, to: callback)

        #expect(callback.events == ["loaded", "skipped"])
    }

    @Test func userCloseAfterDisplayFiresOnce() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverDisplayed(placement, to: callback)
        coordinator.deliverClosed(placement, to: callback)
        coordinator.deliverClosed(placement, to: callback)

        #expect(callback.events.filter { $0 == "closed" }.count == 1)
    }

    @Test func bridgeDeliversFailureWithoutDuplicate() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()
        let bridge = AdSessionCallbackBridge(coordinator: coordinator, downstream: callback)

        bridge.onAdFailed(placement, errorCode: 500, errorMessage: "boom")
        bridge.onAdFailed(placement, errorCode: 500, errorMessage: "boom")

        #expect(callback.events == ["failed"])
    }

    @Test func staleSessionIdIsRejected() {
        let coordinator = AdSessionCoordinator()
        let oldId = coordinator.sessionId
        coordinator.deliverFailed(placement, errorCode: 1, errorMessage: "timeout", to: nil)
        #expect(coordinator.belongsToCurrentSession(oldId) == false)
    }
}

struct RewardedSkipPolicyTests {
    @Test func skipDoesNotRewardWhenAlwaysRewardDisabled() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverLoaded("rewarded", to: callback)
        coordinator.deliverVideoSkipped("rewarded", to: callback)
        coordinator.deliverVideoCompleted("rewarded", to: callback)

        #expect(!callback.events.contains("completed"))
    }
}
