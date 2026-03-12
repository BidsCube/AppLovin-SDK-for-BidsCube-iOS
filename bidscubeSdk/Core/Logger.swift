import Foundation

/// Logger utility for the BidsCube SDK
public class Logger {
    
    // MARK: - Properties
    
    private static var isLoggingEnabled: Bool = true
    private static var isDebugMode: Bool = false
    
    // MARK: - Configuration
    
    /// Enable or disable logging
    public static func setLoggingEnabled(_ enabled: Bool) {
        isLoggingEnabled = enabled
    }
    
    /// Enable or disable debug mode
    public static func setDebugMode(_ enabled: Bool) {
        isDebugMode = enabled
    }
    
    // MARK: - Logging Methods
    
    /// Log an info message
    public static func info(_ message: String, prefix: String = Constants.LogPrefixes.sdk) {
        guard isLoggingEnabled else { return }
        print("\(prefix): \(message)")
    }
    
    /// Log a debug message (only shown in debug mode)
    public static func debug(_ message: String, prefix: String = Constants.LogPrefixes.sdk) {
        guard isLoggingEnabled && isDebugMode else { return }
        print("\(prefix) [DEBUG]: \(message)")
    }
    
    /// Log a warning message
    public static func warning(_ message: String, prefix: String = Constants.LogPrefixes.sdk) {
        guard isLoggingEnabled else { return }
        print("⚠️ \(prefix): \(message)")
    }
    
    /// Log an error message
    public static func error(_ message: String, prefix: String = Constants.LogPrefixes.sdk) {
        guard isLoggingEnabled else { return }
        print("\(Constants.LogPrefixes.error) \(prefix): \(message)")
    }
    
    /// Log a success message
    public static func success(_ message: String, prefix: String = Constants.LogPrefixes.sdk) {
        guard isLoggingEnabled else { return }
        print("\(Constants.LogPrefixes.success) \(prefix): \(message)")
    }
    
    // MARK: - Convenience Methods
    
    /// Log network-related messages
    public static func network(_ message: String) {
        info(message, prefix: Constants.LogPrefixes.network)
    }
    
    /// Log image ad-related messages
    public static func imageAd(_ message: String) {
        info(message, prefix: Constants.LogPrefixes.imageAd)
    }
    
    /// Log video ad-related messages
    public static func videoAd(_ message: String) {
        info(message, prefix: Constants.LogPrefixes.videoAd)
    }
    
    /// Log native ad-related messages
    public static func nativeAd(_ message: String) {
        info(message, prefix: Constants.LogPrefixes.nativeAd)
    }
    
    /// Log URL builder messages
    public static func urlBuilder(_ message: String) {
        info(message, prefix: Constants.LogPrefixes.urlBuilder)
    }
    
    // MARK: - Error Logging
    
    /// Log a network error
    public static func networkError(_ error: NetworkError, context: String = "") {
        let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        self.error(message, prefix: Constants.LogPrefixes.network)
    }
    
    /// Log a general error with context
    public static func error(_ error: Error, context: String = "") {
        let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        self.error(message)
    }
    
    // MARK: - Performance Logging
    
    /// Log performance metrics
    public static func performance(_ operation: String, duration: TimeInterval) {
        guard isLoggingEnabled && isDebugMode else { return }
        let formattedDuration = String(format: "%.3f", duration)
        debug("\(operation) took \(formattedDuration)s")
    }
    
    // MARK: - Device Info Logging
    
    /// Log device information for debugging
    public static func deviceInfo() {
        guard isLoggingEnabled && isDebugMode else { return }
        debug("Device Info:Bundle=\(DeviceInfo.bundleId), App=\(DeviceInfo.appName), Size=\(DeviceInfo.deviceWidth)x\(DeviceInfo.deviceHeight), Language=\(DeviceInfo.language), IFA=\(DeviceInfo.advertisingIdentifier), DNT=\(DeviceInfo.doNotTrack)")
    }
}

// MARK: - Logger Configuration

extension Logger {
    /// Configure logger from SDK configuration
    public static func configure(from config: SDKConfig) {
        setLoggingEnabled(config.enableLogging)
        setDebugMode(config.enableDebugMode)
    }
}
