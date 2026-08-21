import Testing
import UIKit
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

@MainActor
final class UIKitTestHost {
    let window: UIWindow
    let navigationController: UINavigationController

    init() {
        let root = UIViewController()
        root.view.backgroundColor = .white
        navigationController = UINavigationController(rootViewController: root)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        navigationController.loadViewIfNeeded()
    }

    func setRootViewController(_ viewController: UIViewController) {
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.loadViewIfNeeded()
    }

    func tearDown() {
        window.isHidden = true
        window.rootViewController = nil
    }

    func waitUntil(timeout: TimeInterval = 2.0, _ condition: @escaping @MainActor () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            await Task.yield()
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
    }

    func performDismissal(
        _ controller: UIViewController,
        animated: Bool = false,
        timeout: TimeInterval = 3.0
    ) async -> FullscreenDismissalResult {
        await withCheckedContinuation { continuation in
            var finished = false
            FullscreenDismissal.perform(on: controller, animated: animated) { result in
                guard !finished else { return }
                finished = true
                continuation.resume(returning: result)
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard !finished else { return }
                finished = true
                Issue.record("Fullscreen dismissal timed out")
                continuation.resume(returning: .cancelled)
            }
        }
    }
}
