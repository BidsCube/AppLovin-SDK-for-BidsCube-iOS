import UIKit

enum FullscreenDismissalHelper {
    @MainActor
    static func isViewDetachedFromWindow(_ view: UIView) -> Bool {
        view.window == nil && (view.superview?.window == nil)
    }

    @MainActor
    static func resolveAdViewController(from view: UIView) -> AdViewController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let adViewController = current as? AdViewController {
                return adViewController
            }
            responder = current.next
        }
        return nil
    }

    @MainActor
    static func resolveKnownDismissalOwner(from view: UIView) -> UIViewController? {
        if let adViewController = resolveAdViewController(from: view) {
            return adViewController
        }
        return resolveFullscreenDismissalTarget(from: view)
    }

    @MainActor
    static func resolveFullscreenDismissalTarget(from view: UIView) -> UIViewController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let viewController = current as? UIViewController {
                if viewController.presentingViewController != nil {
                    return viewController
                }
                if let navigationController = viewController.navigationController,
                   navigationController.viewControllers.count > 1,
                   navigationController.viewControllers.last === viewController {
                    return viewController
                }
            }
            responder = current.next
        }

        guard let scene = foregroundWindowScene(),
              let window = preferredMainContentWindow(in: scene),
              let root = window.rootViewController else {
            return nil
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top === root ? nil : top
    }

    @MainActor
    static func performFallbackDismissal(
        from view: UIView,
        notifyClosed: Bool,
        placementId: String,
        callback: AdCallback?,
        onNeedsReset: @escaping () -> Void,
        logTag: String
    ) {
        if let adViewController = resolveAdViewController(from: view) {
            adViewController.dismissAdOnce(notifyClosed: notifyClosed)
            return
        }

        if isViewDetachedFromWindow(view) {
            if let scene = foregroundWindowScene(),
               let visibleOwner = findVisibleDismissalOwner(in: scene),
               !FullscreenDismissal.isFullyDismissed(visibleOwner) {
                FullscreenLifecycleDiagnostics.log(
                    logTag,
                    "fallback stillVisible placementId=\(placementId) owner=\(type(of: visibleOwner))"
                )
                onNeedsReset()
                return
            }

            FullscreenLifecycleDiagnostics.log(
                logTag,
                "fallback alreadyDismissed placementId=\(placementId)"
            )
            deliverClosedIfVerified(result: .alreadyDismissed, notifyClosed: notifyClosed, placementId: placementId, callback: callback)
            return
        }

        guard let target = resolveFullscreenDismissalTarget(from: view) else {
            FullscreenLifecycleDiagnostics.log(
                logTag,
                "fallback noDismissPath placementId=\(placementId) viewInWindow=\(view.window != nil)"
            )
            onNeedsReset()
            return
        }

        FullscreenDismissal.perform(on: target, animated: true) { result in
            deliverClosedIfVerified(
                result: result,
                notifyClosed: notifyClosed,
                placementId: placementId,
                callback: callback,
                onNeedsReset: onNeedsReset
            )
        }
    }

    @MainActor
    private static func deliverClosedIfVerified(
        result: FullscreenDismissalResult,
        notifyClosed: Bool,
        placementId: String,
        callback: AdCallback?,
        onNeedsReset: (() -> Void)? = nil
    ) {
        guard notifyClosed else { return }
        switch result {
        case .dismissed, .alreadyDismissed:
            callback?.onAdClosed(placementId)
        case .cancelled, .stillVisible, .noDismissPath:
            onNeedsReset?()
        }
    }

    @MainActor
    private static func foregroundWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
    }

    @MainActor
    private static func preferredMainContentWindow(in scene: UIWindowScene) -> UIWindow? {
        scene.windows.first(where: { window in
            guard window.rootViewController != nil else { return false }
            if isSmokeHarnessOverlayWindow(window) { return false }
            return window.isKeyWindow || window.windowLevel == .normal
        }) ?? scene.windows.first(where: { !isSmokeHarnessOverlayWindow($0) })
    }

    @MainActor
    private static func isSmokeHarnessOverlayWindow(_ window: UIWindow) -> Bool {
        NSStringFromClass(type(of: window)).contains("SmokePassthroughWindow")
    }

    @MainActor
    private static func findVisibleDismissalOwner(in scene: UIWindowScene) -> UIViewController? {
        for window in scene.windows where !isSmokeHarnessOverlayWindow(window) {
            if let owner = findDismissalOwner(in: window.rootViewController) {
                return owner
            }
        }
        return nil
    }

    @MainActor
    private static func findDismissalOwner(in controller: UIViewController?) -> UIViewController? {
        guard let controller else { return nil }
        if controller is AdViewController { return controller }
        if let presented = controller.presentedViewController,
           let owner = findDismissalOwner(in: presented) {
            return owner
        }
        for child in controller.children {
            if let owner = findDismissalOwner(in: child) { return owner }
        }
        return nil
    }
}
