import Foundation
import os

class SDKLogger {
    private static var isLoggingEnabled = true
    private static let logger = os.Logger(subsystem: "com.bidscube.sdk", category: "SDK")
    
    static func setLoggingEnabled(_ enabled: Bool) {
        isLoggingEnabled = enabled
    }
    
    static func d(_ tag: String, _ message: String) {
        guard isLoggingEnabled else { return }
        logger.debug("[\(tag)] \(message)")
        print("🔍 [DEBUG] [\(tag)] \(message)")
    }
    
    static func i(_ tag: String, _ message: String) {
        guard isLoggingEnabled else { return }
        logger.info("[\(tag)] \(message)")
        print("Info: [INFO] [\(tag)] \(message)")
    }
    
    static func w(_ tag: String, _ message: String) {
        guard isLoggingEnabled else { return }
        logger.warning("[\(tag)] \(message)")
        print("⚠️ [WARNING] [\(tag)] \(message)")
    }
    
    static func e(_ tag: String, _ message: String) {
        guard isLoggingEnabled else { return }
        logger.error("[\(tag)] \(message)")
        print("Error: [ERROR] [\(tag)] \(message)")
    }
    
    static func v(_ tag: String, _ message: String) {
        guard isLoggingEnabled else { return }
        logger.debug("[\(tag)] \(message)")
        print("📝 [VERBOSE] [\(tag)] \(message)")
    }
}
