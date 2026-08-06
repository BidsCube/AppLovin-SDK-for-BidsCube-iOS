import Foundation

enum AdSessionState: Equatable {
    case loading
    case loaded
    case displayed
    case failed
    case closed

    var isTerminal: Bool {
        self == .failed || self == .closed
    }
}

/// Centralized ad-session state and once-only callback delivery.
final class AdSessionCoordinator {
    let sessionId = UUID()
    private(set) var state: AdSessionState = .loading
    private var firedEvents = Set<String>()

    var isTerminal: Bool { state.isTerminal }

    func belongsToCurrentSession(_ id: UUID) -> Bool {
        sessionId == id && !isTerminal
    }

    @discardableResult
    func deliverLoading(_ placementId: String, to callback: AdCallback?) -> Bool {
        deliver(event: "loading", allowedBeforeLoaded: true) {
            callback?.onAdLoading(placementId)
        }
    }

    @discardableResult
    func deliverLoaded(_ placementId: String, to callback: AdCallback?) -> Bool {
        deliver(event: "loaded", allowedBeforeLoaded: true) {
            state = .loaded
            callback?.onAdLoaded(placementId)
        }
    }

    @discardableResult
    func deliverDisplayed(_ placementId: String, to callback: AdCallback?) -> Bool {
        guard firedEvents.contains("loaded") else { return false }
        return deliver(event: "displayed", allowedBeforeLoaded: false) {
            state = .displayed
            callback?.onAdDisplayed(placementId)
        }
    }

    @discardableResult
    func deliverClicked(_ placementId: String, to callback: AdCallback?) -> Bool {
        guard firedEvents.contains("loaded") else { return false }
        return deliver(event: "clicked", allowedBeforeLoaded: false) {
            callback?.onAdClicked(placementId)
        }
    }

    @discardableResult
    func deliverFailed(_ placementId: String, errorCode: Int, errorMessage: String, to callback: AdCallback?) -> Bool {
        guard !state.isTerminal else { return false }
        guard !firedEvents.contains("failed") else { return false }
        firedEvents.insert("failed")
        state = .failed
        callback?.onAdFailed(placementId, errorCode: errorCode, errorMessage: errorMessage)
        return true
    }

    @discardableResult
    func deliverClosed(_ placementId: String, to callback: AdCallback?) -> Bool {
        guard state != .closed else { return false }
        guard !firedEvents.contains("closed") else { return false }
        guard state != .failed else { return false }
        firedEvents.insert("closed")
        state = .closed
        callback?.onAdClosed(placementId)
        return true
    }

    @discardableResult
    func deliverVideoStarted(_ placementId: String, to callback: AdCallback?) -> Bool {
        guard firedEvents.contains("loaded") else { return false }
        return deliver(event: "videoStarted", allowedBeforeLoaded: false) {
            if state == .loaded { state = .displayed }
            callback?.onVideoAdStarted(placementId)
        }
    }

    @discardableResult
    func deliverVideoCompleted(_ placementId: String, to callback: AdCallback?) -> Bool {
        guard !firedEvents.contains("skipped") else { return false }
        guard firedEvents.contains("loaded") else { return false }
        return deliver(event: "videoCompleted", allowedBeforeLoaded: false) {
            callback?.onVideoAdCompleted(placementId)
        }
    }

    @discardableResult
    func deliverVideoSkipped(_ placementId: String, to callback: AdCallback?) -> Bool {
        guard !firedEvents.contains("videoCompleted") else { return false }
        guard firedEvents.contains("loaded") else { return false }
        return deliver(event: "skipped", allowedBeforeLoaded: false) {
            firedEvents.insert("videoCompleted")
            callback?.onVideoAdSkipped(placementId)
        }
    }

    @discardableResult
    func deliverVideoSkippable(_ placementId: String, to callback: AdCallback?) -> Bool {
        guard firedEvents.contains("loaded") else { return false }
        return deliver(event: "videoSkippable", allowedBeforeLoaded: false) {
            callback?.onVideoAdSkippable(placementId)
        }
    }

    func invalidate() {
        if state == .closed || state == .failed { return }
        firedEvents.insert("failed")
        state = .failed
    }

    private func deliver(
        event: String,
        allowedBeforeLoaded: Bool,
        action: () -> Void
    ) -> Bool {
        guard !state.isTerminal else { return false }
        if !allowedBeforeLoaded, !firedEvents.contains("loaded"), state != .loaded, state != .displayed {
            return false
        }
        guard !firedEvents.contains(event) else { return false }
        firedEvents.insert(event)
        action()
        return true
    }
}

/// Routes ad view callbacks through a shared session coordinator.
final class AdSessionCallbackBridge: AdCallback {
    private let coordinator: AdSessionCoordinator
    private let downstream: AdCallback?
    private let onLoaded: ((String) -> Void)?
    private let onFailed: ((String, Int, String) -> Void)?

    init(
        coordinator: AdSessionCoordinator,
        downstream: AdCallback?,
        onLoaded: ((String) -> Void)? = nil,
        onFailed: ((String, Int, String) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.downstream = downstream
        self.onLoaded = onLoaded
        self.onFailed = onFailed
    }

    func onAdLoading(_ placementId: String) {
        coordinator.deliverLoading(placementId, to: downstream)
    }

    func onAdLoaded(_ placementId: String) {
        if coordinator.deliverLoaded(placementId, to: downstream) {
            onLoaded?(placementId)
        }
    }

    func onAdDisplayed(_ placementId: String) {
        coordinator.deliverDisplayed(placementId, to: downstream)
    }

    func onAdClicked(_ placementId: String) {
        coordinator.deliverClicked(placementId, to: downstream)
    }

    func onAdClosed(_ placementId: String) {
        coordinator.deliverClosed(placementId, to: downstream)
    }

    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        if coordinator.deliverFailed(placementId, errorCode: errorCode, errorMessage: errorMessage, to: downstream) {
            onFailed?(placementId, errorCode, errorMessage)
        }
    }

    func onVideoAdStarted(_ placementId: String) {
        coordinator.deliverVideoStarted(placementId, to: downstream)
    }

    func onVideoAdCompleted(_ placementId: String) {
        coordinator.deliverVideoCompleted(placementId, to: downstream)
    }

    func onVideoAdSkipped(_ placementId: String) {
        coordinator.deliverVideoSkipped(placementId, to: downstream)
    }

    func onVideoAdSkippable(_ placementId: String) {
        coordinator.deliverVideoSkippable(placementId, to: downstream)
    }

    func onInstallButtonClicked(_ placementId: String, buttonText: String) {
        downstream?.onInstallButtonClicked(placementId, buttonText: buttonText)
    }

    func onAdRenderOverride(adm: String, position: AdPosition) {
        downstream?.onAdRenderOverride(adm: adm, position: position)
    }
}
