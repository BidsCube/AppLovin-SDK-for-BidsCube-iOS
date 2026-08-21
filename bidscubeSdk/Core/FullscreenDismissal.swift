import UIKit

enum FullscreenDismissalResult: Equatable {
    case dismissed
    case alreadyDismissed
    case cancelled
    case stillVisible
    case noDismissPath
}

/// Dismisses a fullscreen ad view controller and reports whether UIKit teardown actually completed.
enum FullscreenDismissal {
    static func perform(
        on viewController: UIViewController,
        animated: Bool = true,
        completion: @escaping (FullscreenDismissalResult) -> Void
    ) {
        let runOnMain: (@escaping () -> Void) -> Void = { work in
            if Thread.isMainThread {
                work()
            } else {
                DispatchQueue.main.async(execute: work)
            }
        }

        runOnMain {
            log(viewController, "dismissal_requested")

            if isFullyDismissed(viewController) {
                verifyOnNextRunLoop(viewController) { verified in
                    log(viewController, verified ? "dismissal_verified" : "dismissal_failed_still_visible")
                    completion(verified ? .alreadyDismissed : .stillVisible)
                }
                return
            }

            attemptDismiss(viewController, animated: animated, isRetry: false, completion: completion)
        }
    }

    static func isFullyDismissed(_ viewController: UIViewController) -> Bool {
        let inWindow = viewController.view.window != nil
        let stillPresented = viewController.presentingViewController != nil
        let inNavigationStack = viewController.navigationController?.viewControllers.contains(viewController) == true
        return !inWindow && !stillPresented && !inNavigationStack
    }

    private static func attemptDismiss(
        _ viewController: UIViewController,
        animated: Bool,
        isRetry: Bool,
        completion: @escaping (FullscreenDismissalResult) -> Void
    ) {
        if let navigationController = viewController.navigationController,
           navigationController.viewControllers.count > 1,
           navigationController.viewControllers.last === viewController {
            navigationController.popViewController(animated: animated)
            if let transition = navigationController.transitionCoordinator {
                transition.animate(alongsideTransition: nil) { context in
                    if context.isCancelled {
                        log(viewController, "dismissal_cancelled")
                        completion(.cancelled)
                    } else {
                        log(viewController, "dismissal_transition_completed")
                        finishVerification(viewController, isRetry: isRetry, completion: completion)
                    }
                }
            } else {
                log(viewController, "dismissal_transition_completed")
                finishVerification(viewController, isRetry: isRetry, completion: completion)
            }
            return
        }

        if viewController.presentingViewController != nil {
            viewController.dismiss(animated: animated) {
                log(viewController, "dismissal_transition_completed")
                finishVerification(viewController, isRetry: isRetry, completion: completion)
            }
            return
        }

        log(viewController, "dismissal_no_path")

        if isRetry {
            verifyOnNextRunLoop(viewController) { verified in
                log(viewController, verified ? "dismissal_verified" : "dismissal_failed_still_visible")
                completion(verified ? .dismissed : .noDismissPath)
            }
            return
        }

        DispatchQueue.main.async {
            log(viewController, "dismissal_retry_next_runloop")
            if isFullyDismissed(viewController) {
                verifyOnNextRunLoop(viewController) { verified in
                    completion(verified ? .alreadyDismissed : .stillVisible)
                }
                return
            }
            attemptDismiss(viewController, animated: animated, isRetry: true, completion: completion)
        }
    }

    private static func finishVerification(
        _ viewController: UIViewController,
        isRetry: Bool,
        completion: @escaping (FullscreenDismissalResult) -> Void
    ) {
        verifyOnNextRunLoop(viewController) { verified in
            if verified {
                log(viewController, "dismissal_verified")
                completion(.dismissed)
                return
            }

            log(viewController, "dismissal_failed_still_visible window=\(viewController.view.window != nil) presenting=\(viewController.presentingViewController != nil) nav=\(viewController.navigationController?.viewControllers.contains(viewController) == true)")

            if isRetry {
                completion(.stillVisible)
                return
            }

            DispatchQueue.main.async {
                log(viewController, "dismissal_retry_next_runloop")
                attemptDismiss(viewController, animated: false, isRetry: true, completion: completion)
            }
        }
    }

    private static func verifyOnNextRunLoop(
        _ viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        DispatchQueue.main.async {
            completion(isFullyDismissed(viewController))
        }
    }

    private static func log(_ viewController: UIViewController, _ message: String) {
        FullscreenLifecycleDiagnostics.log(
            "FullscreenDismissal",
            message,
            controller: viewController
        )
    }
}
