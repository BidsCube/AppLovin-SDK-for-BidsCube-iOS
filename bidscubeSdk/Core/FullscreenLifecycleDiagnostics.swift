import Foundation

enum FullscreenLifecycleDiagnostics {
    static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    static func threadLabel() -> String {
        Thread.isMainThread ? "main" : "background"
    }

    static func objectID(_ object: AnyObject?) -> String {
        guard let object else { return "nil" }
        return String(format: "%p", unsafeBitCast(object, to: Int.self))
    }

    static func log(
        _ tag: String,
        _ message: String,
        placementId: String? = nil,
        sessionId: UUID? = nil,
        handler: AnyObject? = nil,
        controller: AnyObject? = nil
    ) {
        var parts = ["[\(tag)]", "[\(timestamp())]", "[\(threadLabel())]"]
        if let placementId, !placementId.isEmpty {
            parts.append("placementId=\(placementId)")
        }
        if let sessionId {
            parts.append("sessionId=\(sessionId.uuidString.prefix(8))")
        }
        if let handler {
            parts.append("handler_id=\(objectID(handler))")
        }
        if let controller {
            parts.append("controller_id=\(objectID(controller))")
        }
        parts.append(message)
        let line = parts.joined(separator: " ")
        print(line)
        testEventRecorder?(tag, message)
    }

    static var testEventRecorder: ((String, String) -> Void)?
}
