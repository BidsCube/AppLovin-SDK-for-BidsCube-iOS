import Foundation

/// Ensures video ad callbacks fire at most once per session phase.
final class VideoCallbackGuard {
    private var fired = Set<String>()
    private(set) var hasFailed = false
    private(set) var hasClosed = false

    func fireOnce(_ key: String, action: () -> Void) {
        guard !fired.contains(key) else { return }
        if key != "failed", hasFailed { return }
        if key != "closed", hasClosed { return }
        fired.insert(key)
        if key == "failed" { hasFailed = true }
        if key == "closed" { hasClosed = true }
        action()
    }

    func hasFired(_ key: String) -> Bool {
        fired.contains(key)
    }
}
