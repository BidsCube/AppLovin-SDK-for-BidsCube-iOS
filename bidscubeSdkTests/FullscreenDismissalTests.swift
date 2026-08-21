import Foundation
import Testing
import UIKit
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

private final class RecordingAdCallback: AdCallback {
    var closedCount = 0

    func onAdLoading(_ placementId: String) {}
    func onAdLoaded(_ placementId: String) {}
    func onAdDisplayed(_ placementId: String) {}
    func onAdClicked(_ placementId: String) {}
    func onAdClosed(_ placementId: String) { closedCount += 1 }
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {}
    func onVideoAdStarted(_ placementId: String) {}
    func onVideoAdCompleted(_ placementId: String) {}
    func onVideoAdSkipped(_ placementId: String) {}
    func onVideoAdSkippable(_ placementId: String) {}
}

private final class FakePresentedViewController: UIViewController {
    weak var fakePresenter: UIViewController?

    override var presentingViewController: UIViewController? { fakePresenter }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let fakePresenter else {
            completion?()
            return
        }
        if let presenter = fakePresenter as? TestModalPresenter {
            presenter.dismissModal(presented: self, completion: completion)
        } else {
            completion?()
        }
    }
}

private final class TestModalPresenter: UIViewController {
    fileprivate func dismissModal(presented: UIViewController, completion: (() -> Void)?) {
        presented.willMove(toParent: nil)
        presented.view.removeFromSuperview()
        presented.removeFromParent()
        if let fake = presented as? FakePresentedViewController {
            fake.fakePresenter = nil
        }
        completion?()
    }
}

private func installModalPresentation(presenter: TestModalPresenter, presented: FakePresentedViewController) {
    presented.modalPresentationStyle = .fullScreen
    presented.fakePresenter = presenter
    presenter.addChild(presented)
    presenter.view.addSubview(presented.view)
    presented.view.frame = presenter.view.bounds
    presented.didMove(toParent: presenter)
}

private let cachedTestMarkup = """
<html><body><div style="width:320px;height:50px;background:#000"></div></body></html>
"""

@Suite(.serialized)
@MainActor
struct FullscreenDismissalTests {

    @Test func alreadyDismissedControllerReturnsAlreadyDismissed() async {
        let host = UIKitTestHost()
        defer { host.tearDown() }
        let result = await host.performDismissal(UIViewController())
        #expect(result == .alreadyDismissed)
    }

    @Test func fakeChildModalDismissalRemovesControllerFromHierarchy() async {
        let host = UIKitTestHost()
        defer { host.tearDown() }

        let presenter = TestModalPresenter()
        presenter.view.backgroundColor = .white
        host.window.rootViewController = presenter
        presenter.loadViewIfNeeded()
        _ = await host.waitUntil(timeout: 3) { presenter.view.window != nil }

        let presented = FakePresentedViewController()
        presented.loadViewIfNeeded()
        installModalPresentation(presenter: presenter, presented: presented)

        let ready = await host.waitUntil(timeout: 3) {
            presented.presentingViewController != nil && presented.view.window != nil
        }
        #expect(ready, "Presentation failed in UIKit test host")

        let result = await host.performDismissal(presented, animated: false)
        #expect(result == .dismissed)
        #expect(presented.view.window == nil)
        #expect(presented.presentingViewController == nil)
    }

    @Test func realUIKitModalPresentDismissalRemovesControllerFromHierarchy() async {
        guard UIApplication.shared.connectedScenes.contains(where: { $0 is UIWindowScene }) else {
            return
        }
        let host = UIKitTestHost()
        defer { host.tearDown() }

        let root = UIViewController()
        root.view.backgroundColor = .white
        host.setRootViewController(root)
        _ = await host.waitUntil(timeout: 3) { root.view.window != nil }

        let presented = UIViewController()
        presented.modalPresentationStyle = .fullScreen
        presented.loadViewIfNeeded()
        root.present(presented, animated: false)
        _ = await host.waitUntil(timeout: 3) { presented.viewIfLoaded?.window != nil }

        let presentedReady = await host.waitUntil(timeout: 3) {
            root.presentedViewController === presented
                && presented.presentingViewController === root
                && presented.view.window === host.window
        }
        #expect(presentedReady, "Real UIKit present failed")

        let result = await host.performDismissal(presented, animated: false)
        #expect(result == .dismissed)
        #expect(root.presentedViewController == nil)
        #expect(presented.presentingViewController == nil)
        #expect(presented.view.window == nil)
    }

    @Test func navigationDismissalPopsController() async {
        let host = UIKitTestHost()
        defer { host.tearDown() }

        let pushed = UIViewController()
        pushed.loadViewIfNeeded()
        host.navigationController.pushViewController(pushed, animated: false)
        let ready = await host.waitUntil { host.navigationController.viewControllers.contains(pushed) }
        #expect(ready, "Pushed controller not in navigation stack")

        let result = await host.performDismissal(pushed, animated: false)
        #expect(result == .dismissed)
        #expect(!host.navigationController.viewControllers.contains(pushed))
    }

    @Test func visibleHandlerHasNoDismissPath() async {
        let host = UIKitTestHost()
        defer { host.tearDown() }

        let handler = UIView(frame: host.navigationController.view.bounds)
        host.navigationController.view.addSubview(handler)
        host.navigationController.view.layoutIfNeeded()
        let ready = await host.waitUntil { handler.window != nil }
        #expect(ready, "Pushed controller not in navigation stack")

        let callback = RecordingAdCallback()
        var resetCount = 0
        FullscreenDismissalHelper.performFallbackDismissal(
            from: handler,
            notifyClosed: true,
            placementId: "no-path",
            callback: callback,
            onNeedsReset: { resetCount += 1 },
            logTag: "FullscreenDismissalTests"
        )
        #expect(callback.closedCount == 0)
        #expect(resetCount == 1)
    }

    @Test func duplicateDismissAdOnceOnlyDismissesOnce() async {
        let host = UIKitTestHost()
        defer { host.tearDown() }

        let callback = RecordingAdCallback()
        let controller = AdViewController(
            placementId: "dup-dismiss",
            adType: .image,
            cachedResponseBody: cachedTestMarkup,
            callback: callback
        )
        controller.loadViewIfNeeded()
        host.navigationController.pushViewController(controller, animated: false)
        let ready = await host.waitUntil { controller.view.window != nil }
        #expect(ready, "Pushed controller not in navigation stack")

        var events: [String] = []
        FullscreenLifecycleDiagnostics.testEventRecorder = { tag, message in
            events.append("\(tag):\(message)")
        }
        defer { FullscreenLifecycleDiagnostics.testEventRecorder = nil }

        controller.dismissAdOnce()
        controller.dismissAdOnce()
        _ = await host.waitUntil(timeout: 3.0) {
            callback.closedCount == 1
        }

        #expect(events.filter { $0 == "AdViewController:dismissal_requested" }.count == 1)
        #expect(callback.closedCount == 1)
    }

    @Test func dismissalCallbackOrderIsVerifiedBeforeClosed() async {
        let host = UIKitTestHost()
        defer { host.tearDown() }

        let callback = RecordingAdCallback()
        let controller = AdViewController(
            placementId: "order-test",
            adType: .image,
            cachedResponseBody: cachedTestMarkup,
            callback: callback
        )
        controller.loadViewIfNeeded()
        host.navigationController.pushViewController(controller, animated: false)
        _ = await host.waitUntil { controller.view.window != nil }

        var events: [String] = []
        FullscreenLifecycleDiagnostics.testEventRecorder = { tag, message in
            events.append("\(tag):\(message)")
        }
        defer { FullscreenLifecycleDiagnostics.testEventRecorder = nil }

        controller.dismissAdOnce()
        _ = await host.waitUntil(timeout: 3.0) { callback.closedCount == 1 }

        let requested = events.firstIndex { $0.contains("dismissal_requested") }
        let transition = events.firstIndex { $0.contains("dismissal_transition_completed") }
        let verified = events.firstIndex { $0.contains("dismissal_verified") }
        let closed = events.firstIndex { $0.contains("onAdClosed_delivered") }

        #expect(requested != nil)
        #expect(transition != nil)
        #expect(verified != nil)
        #expect(closed != nil)
        if let requested, let transition, let verified, let closed {
            #expect(requested < transition)
            #expect(transition < verified)
            #expect(verified < closed)
        }
    }
}

@Suite(.serialized)
@MainActor
struct FullscreenFallbackDismissalTests {
    @Test func handlerWithoutControllerAndWithoutWindowIsAlreadyDismissed() {
        let handler = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let callback = RecordingAdCallback()
        FullscreenDismissalHelper.performFallbackDismissal(
            from: handler,
            notifyClosed: true,
            placementId: "fallback-test",
            callback: callback,
            onNeedsReset: {},
            logTag: "FullscreenFallbackDismissalTests"
        )
        #expect(callback.closedCount == 1)
    }

    @Test func handlerInWindowWithoutDismissPathDoesNotClose() async {
        let host = UIKitTestHost()
        defer { host.tearDown() }
        let handler = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        host.navigationController.view.addSubview(handler)
        host.navigationController.view.layoutIfNeeded()
        _ = await host.waitUntil { handler.window != nil }

        let callback = RecordingAdCallback()
        var resetCount = 0
        FullscreenDismissalHelper.performFallbackDismissal(
            from: handler,
            notifyClosed: true,
            placementId: "fallback-test",
            callback: callback,
            onNeedsReset: { resetCount += 1 },
            logTag: "FullscreenFallbackDismissalTests"
        )
        #expect(callback.closedCount == 0)
        #expect(resetCount == 1)
    }

    @Test func cancelledStillVisibleAndNoDismissPathDoNotDeliverClosed() {
        let callback = RecordingAdCallback()
        for result in [FullscreenDismissalResult.cancelled, .stillVisible, .noDismissPath] {
            callback.closedCount = 0
            if result == .dismissed || result == .alreadyDismissed {
                callback.onAdClosed("blocked")
            }
            #expect(callback.closedCount == 0)
        }
    }
}

@Suite(.serialized)
@MainActor
struct BridgeRetentionTests {
    @Test func sessionCallbackBridgeRetainedDuringLoadAd() {
        let controller = AdViewController(
            placementId: "retention-test",
            adType: .image,
            cachedResponseBody: cachedTestMarkup,
            callback: nil
        )
        controller.loadViewIfNeeded()
        controller.bidscubeInvalidateLoadingTimeoutForTesting()
        #expect(controller.bidscubeSessionCallbackBridgeForTesting != nil)
    }

    @Test func sessionCallbackBridgeReleasedAfterControllerDeinit() async {
        weak var weakBridge: AdSessionCallbackBridge?
        weak var weakController: AdViewController?

        autoreleasepool {
            let controller = AdViewController(
                placementId: "retention-deinit",
                adType: .video,
                callback: nil
            )
            controller.bidscubeEstablishSessionBridgeForTesting()
            weakController = controller
            weakBridge = controller.bidscubeSessionCallbackBridgeForTesting
            #expect(weakBridge != nil)
        }

        _ = await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(weakController == nil)
        #expect(weakBridge == nil)
    }

    @Test func bridgeReleasedDoesNotRetainDownstreamCallback() async {
        weak var weakCallback: RecordingAdCallback?

        autoreleasepool {
            let callback = RecordingAdCallback()
            weakCallback = callback
            let controller = AdViewController(
                placementId: "bridge-downstream",
                adType: .video,
                callback: callback
            )
            controller.bidscubeEstablishSessionBridgeForTesting()
            _ = controller.bidscubeSessionCallbackBridgeForTesting
        }

        _ = await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(weakCallback == nil)
    }
}
