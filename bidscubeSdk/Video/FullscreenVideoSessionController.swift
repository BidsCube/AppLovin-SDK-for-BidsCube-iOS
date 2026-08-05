import Foundation

/// Pure state machine for fullscreen video post-linear playback.
final class FullscreenVideoSessionController {
    let autoClose: Bool
    private let playerManagesPostVideo: Bool
    private let hasStaticCompanion: Bool
    private let hasHtmlCompanion: Bool

    private var linearCompleted = false
    private var skipped = false
    private var adSessionCompleted = false
    private var adClosed = false
    private var linearPostVideoHandled = false
    private var sessionPostVideoHandled = false
    private var manualCloseShown = false
    private var staticCompanionShown = false
    private var htmlCompanionShown = false

    convenience init(autoClose: Bool, playerManagesPostVideo: Bool, vastXml: String?) {
        self.init(
            autoClose: autoClose,
            playerManagesPostVideo: playerManagesPostVideo,
            companion: vastXml.flatMap { VastParser.selectPostVideoCompanion($0) }
        )
    }

    init(autoClose: Bool, playerManagesPostVideo: Bool, companion: CompanionAd?) {
        self.autoClose = autoClose
        self.playerManagesPostVideo = playerManagesPostVideo
        self.hasHtmlCompanion = companion?.isInteractive == true
        self.hasStaticCompanion = companion?.isStaticImage == true
    }

    init(autoClose: Bool, playerManagesPostVideo: Bool, hasStaticCompanion: Bool, hasHtmlCompanion: Bool) {
        self.autoClose = autoClose
        self.playerManagesPostVideo = playerManagesPostVideo
        self.hasStaticCompanion = hasStaticCompanion
        self.hasHtmlCompanion = hasHtmlCompanion
    }

    var isAdClosed: Bool { adClosed }

    func shouldFireLinearCompleted() -> Bool {
        if skipped { return false }
        if linearCompleted { return false }
        linearCompleted = true
        return true
    }

    func shouldFireSkipped() -> Bool {
        if linearCompleted { return false }
        if skipped { return false }
        skipped = true
        return true
    }

    func shouldFireAdSessionCompleted() -> Bool {
        if adSessionCompleted { return false }
        adSessionCompleted = true
        return true
    }

    func onLinearCompleted() -> FullscreenPostVideoAction {
        linearCompleted = true
        return onLinearPlaybackEnded(wasSkipped: false)
    }

    func onSkipped() -> FullscreenPostVideoAction {
        skipped = true
        return onLinearPlaybackEnded(wasSkipped: true)
    }

    func onAdSessionCompleted() -> FullscreenPostVideoAction {
        adSessionCompleted = true
        if autoClose {
            return adClosed ? .noop : closeEntireAd()
        }
        if adClosed { return .noop }
        if !playerManagesPostVideo {
            return linearPostVideoHandled ? .noop : onNonImaLinearPlaybackEnded()
        }
        return onImaSessionCompleted()
    }

    func onPlaybackFailed() -> FullscreenPostVideoAction {
        if autoClose {
            return adClosed ? .noop : closeEntireAd()
        }
        if adClosed { return .noop }
        linearPostVideoHandled = true
        sessionPostVideoHandled = true
        return finalManualCloseState(releasePlayer: true, hidePlayer: true)
    }

    func onUserClose() -> FullscreenPostVideoAction {
        closeEntireAd()
    }

    private func onLinearPlaybackEnded(wasSkipped: Bool) -> FullscreenPostVideoAction {
        if autoClose {
            return closeEntireAd()
        }
        if wasSkipped {
            return onSkippedManualMode()
        }
        if playerManagesPostVideo {
            return onImaLinearCompleted()
        }
        return onNonImaLinearPlaybackEnded()
    }

    private func onImaLinearCompleted() -> FullscreenPostVideoAction {
        if linearPostVideoHandled { return .noop }
        linearPostVideoHandled = true
        var action = FullscreenPostVideoAction()
        action.removeSkipOverlay = true
        action.keepPlayerVisible = true
        action.showManualCloseButton = shouldShowManualCloseButton()
        return action
    }

    private func onImaSessionCompleted() -> FullscreenPostVideoAction {
        if sessionPostVideoHandled { return .noop }
        sessionPostVideoHandled = true
        if hasHtmlCompanion || hasStaticCompanion {
            return companionOrFinalState(releasePlayer: true, hidePlayer: true)
        }
        // Linear phase already kept the player visible for the last frame / post-roll.
        return .noop
    }

    private func onNonImaLinearPlaybackEnded() -> FullscreenPostVideoAction {
        if linearPostVideoHandled { return .noop }
        linearPostVideoHandled = true
        if hasHtmlCompanion || hasStaticCompanion {
            return companionOrFinalState(releasePlayer: true, hidePlayer: true)
        }
        var action = FullscreenPostVideoAction()
        action.removeSkipOverlay = true
        action.keepPlayerVisible = true
        action.showManualCloseButton = shouldShowManualCloseButton()
        return action
    }

    private func onSkippedManualMode() -> FullscreenPostVideoAction {
        if linearPostVideoHandled { return .noop }
        linearPostVideoHandled = true
        sessionPostVideoHandled = true
        return finalManualCloseState(releasePlayer: true, hidePlayer: true)
    }

    private func companionOrFinalState(releasePlayer: Bool, hidePlayer: Bool) -> FullscreenPostVideoAction {
        if hasHtmlCompanion {
            var action = FullscreenPostVideoAction()
            action.removeSkipOverlay = true
            action.releasePlayer = releasePlayer
            action.hidePlayer = hidePlayer
            action.showHtmlCompanionEndCard = markHtmlCompanionShown()
            return action
        }
        if hasStaticCompanion {
            var action = FullscreenPostVideoAction()
            action.removeSkipOverlay = true
            action.releasePlayer = releasePlayer
            action.hidePlayer = hidePlayer
            action.showStaticCompanionEndCard = markStaticCompanionShown()
            return action
        }
        return finalManualCloseState(releasePlayer: releasePlayer, hidePlayer: hidePlayer)
    }

    private func finalManualCloseState(releasePlayer: Bool, hidePlayer: Bool) -> FullscreenPostVideoAction {
        var action = FullscreenPostVideoAction()
        action.removeSkipOverlay = true
        action.releasePlayer = releasePlayer
        action.hidePlayer = hidePlayer
        action.showManualCloseButton = shouldShowManualCloseButton()
        return action
    }

    private func shouldShowManualCloseButton() -> Bool {
        if manualCloseShown { return false }
        manualCloseShown = true
        return true
    }

    private func markStaticCompanionShown() -> Bool {
        if staticCompanionShown { return false }
        staticCompanionShown = true
        return true
    }

    private func markHtmlCompanionShown() -> Bool {
        if htmlCompanionShown { return false }
        htmlCompanionShown = true
        return true
    }

    @discardableResult
    private func closeEntireAd() -> FullscreenPostVideoAction {
        if adClosed { return .noop }
        adClosed = true
        var action = FullscreenPostVideoAction()
        action.removeSkipOverlay = true
        action.releasePlayer = true
        action.hidePlayer = true
        action.dismissDialog = true
        action.fireAdClosed = true
        return action
    }
}
