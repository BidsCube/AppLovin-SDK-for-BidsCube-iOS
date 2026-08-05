import Foundation

struct FullscreenPostVideoAction: Equatable {
    static let noop = FullscreenPostVideoAction()

    var removeSkipOverlay = false
    var releasePlayer = false
    var hidePlayer = false
    var keepPlayerVisible = false
    var dismissDialog = false
    var fireAdClosed = false
    var showStaticCompanionEndCard = false
    var showHtmlCompanionEndCard = false
    var showManualCloseButton = false

    var isNoop: Bool {
        self == .noop
    }
}
