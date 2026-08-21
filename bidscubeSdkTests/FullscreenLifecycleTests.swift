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
@MainActor
struct FullscreenLifecycleTests {
    private let placement = "lifecycle-placement"

    @Test func imaPlaybackStartDeliversDisplayedBeforeVideoStarted() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()
        let bridge = AdSessionCallbackBridge(coordinator: coordinator, downstream: callback)

        bridge.onAdLoaded(placement)
        bridge.onAdDisplayed(placement)
        bridge.onVideoAdStarted(placement)

        #expect(callback.events == ["loaded", "displayed", "started"])
    }

    @Test func videoStartedWithoutExplicitDisplayedStillMarksSessionDisplayed() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverVideoStarted(placement, to: callback)

        #expect(callback.events == ["loaded", "started"])
        #expect(coordinator.state == .displayed)
    }

    @Test func closedCallbackFiresOnceThroughCoordinator() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()

        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverDisplayed(placement, to: callback)
        coordinator.deliverClosed(placement, to: callback)
        coordinator.deliverClosed(placement, to: callback)

        #expect(callback.events.filter { $0 == "closed" }.count == 1)
    }

    @Test func interstitialLifecycleOrderIsDisplayedThenClosed() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()
        let bridge = AdSessionCallbackBridge(coordinator: coordinator, downstream: callback)

        bridge.onAdLoaded(placement)
        bridge.onAdDisplayed(placement)
        bridge.onAdClosed(placement)

        #expect(callback.events == ["loaded", "displayed", "closed"])
        let displayedIndex = callback.events.firstIndex(of: "displayed")
        let closedIndex = callback.events.firstIndex(of: "closed")
        #expect(displayedIndex! < closedIndex!)
    }

    @Test func maxAdapterTimeoutIsBelowGeneralSspTimeout() {
        #expect(Constants.maxAdapterAdRequestTimeoutMs < Constants.adRequestTimeoutMs)
        #expect(Constants.maxAdapterAdRequestTimeoutMs == 8_000)
    }

    @Test func rewardGrantedAtMostOnceByPolicy() {
        #expect(RewardedGrantPolicy.shouldGrantReward(videoCompleted: true, alwaysRewardUser: false))
        #expect(!RewardedGrantPolicy.shouldGrantReward(videoCompleted: false, alwaysRewardUser: false))
        #expect(RewardedGrantPolicy.shouldGrantReward(videoCompleted: false, alwaysRewardUser: true))
    }

    @Test func skipDoesNotQualifyForRewardUnlessAlwaysRewardEnabled() {
        #expect(!RewardedGrantPolicy.shouldGrantReward(videoCompleted: false, alwaysRewardUser: false))
        #expect(RewardedGrantPolicy.shouldGrantReward(videoCompleted: false, alwaysRewardUser: true))
    }

    @Test func secondAdSessionCanStartAfterClose() {
        let callback = RecordingAdCallback()
        let first = AdSessionCoordinator()
        first.deliverLoaded(placement, to: callback)
        first.deliverDisplayed(placement, to: callback)
        first.deliverClosed(placement, to: callback)

        let second = AdSessionCoordinator()
        second.deliverLoaded(placement, to: callback)
        second.deliverDisplayed(placement, to: callback)

        #expect(callback.events == ["loaded", "displayed", "closed", "loaded", "displayed"])
        #expect(second.state == .displayed)
    }

    @Test func videoStartedDoesNotSynthesizeLoaded() {
        var loadedHookCount = 0
        var playbackHookCount = 0
        var violation: String?
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()
        let bridge = AdSessionCallbackBridge(
            coordinator: coordinator,
            downstream: callback,
            onLoaded: { _ in loadedHookCount += 1 },
            onPlaybackStarted: { _ in playbackHookCount += 1 },
            onLifecycleViolation: { _, reason in violation = reason }
        )

        bridge.onVideoAdStarted(placement)

        #expect(loadedHookCount == 0)
        #expect(playbackHookCount == 0)
        #expect(violation == "videoStarted before loaded")
        #expect(!callback.events.contains("loaded"))
    }

    @Test func videoStartedAfterLoadedInvokesPlaybackHookOnly() {
        var loadedHookCount = 0
        var playbackHookCount = 0
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()
        let bridge = AdSessionCallbackBridge(
            coordinator: coordinator,
            downstream: callback,
            onLoaded: { _ in loadedHookCount += 1 },
            onPlaybackStarted: { _ in playbackHookCount += 1 }
        )

        bridge.onAdLoaded(placement)
        bridge.onVideoAdStarted(placement)

        #expect(loadedHookCount == 1)
        #expect(playbackHookCount == 1)
        #expect(callback.events == ["loaded", "started"])
    }

    @Test func loadingTimeoutGuardWhenVideoStarted() {
        let callback = RecordingAdCallback()
        let coordinator = AdSessionCoordinator()
        coordinator.deliverLoading(placement, to: callback)
        coordinator.deliverLoaded(placement, to: callback)
        coordinator.deliverVideoStarted(placement, to: callback)

        #expect(coordinator.state == .displayed)
    }
}
