import Foundation
import UIKit
import AdSupport

public struct DeviceInfo {
    
    public static var bundleId: String {
        Bundle.main.bundleIdentifier ?? "com.unknown.app"
    }
    
    public static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown App"
    }
    
    public static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
   public static var appStoreURL: String {
    if let appStoreURL = Bundle.main.object(forInfoDictionaryKey: "AppStoreURL") as? String {
        return appStoreURL
    }
    
    return "https://apps.apple.com"
}
    
    public static var deviceWidth: Int {
        Int(UIScreen.main.bounds.width * UIScreen.main.scale)
    }
    
    public static var deviceHeight: Int {
        Int(UIScreen.main.bounds.height * UIScreen.main.scale)
    }
    
    public static var language: String {
        Locale.preferredLanguages.first ?? "en"
    }
    
    public static var userAgent: String {
        let osVersionToken = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        let safariVersionToken = systemMajorMinorVersion
        let cpuToken = UIDevice.current.userInterfaceIdiom == .pad ? "iPad; CPU OS" : "iPhone; CPU iPhone OS"

        return "Mozilla/5.0 (\(cpuToken) \(osVersionToken) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(safariVersionToken) Mobile/15E148 Safari/604.1"
    }

    private static var systemMajorMinorVersion: String {
        let versionParts = UIDevice.current.systemVersion.split(separator: ".")
        if versionParts.count >= 2 {
            return "\(versionParts[0]).\(versionParts[1])"
        }
        return UIDevice.current.systemVersion
    }
    
    public static var isTrackingEnabled: Bool {
        if #available(iOS 14, *) {
            return ASIdentifierManager.shared().isAdvertisingTrackingEnabled
        } else {
            return true
        }
    }
    
    public static var advertisingIdentifier: String {
        guard isTrackingEnabled else {
            return "12345678-1234-1234-1234-123456789012"
        }
        
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    public static var doNotTrack: Int {
        return isTrackingEnabled ? 0 : 1
    }
    
    public static var gdpr: String {
        let euCountries = ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"]
        let currentCountry = Locale.current.regionCode ?? ""
        return euCountries.contains(currentCountry) ? "1" : "0"
    }
    
    public static var gdprConsent: String {
        // Try to get GDPR consent from UserDefaults first
        if let gdprConsent = UserDefaults.standard.string(forKey: "IABTCF_TCString") {
            return gdprConsent
        }
        
        // Fallback: check if user has given consent to data processing
        if let hasConsent = UserDefaults.standard.object(forKey: "IABTCF_PurposeConsents") as? String {
            // Check if consent is given for purpose 1 (storage and access of information)
            if hasConsent.count > 0 && hasConsent.first == "1" {
                return "1"
            }
        }
        
        // Default to no consent if not found
        return "0"
    }
    
    public static var usPrivacy: String {
        // Try to get US Privacy string from UserDefaults
        if let usPrivacyString = UserDefaults.standard.string(forKey: "IABUSPrivacy_String") {
            return usPrivacyString
        }
        
        // Fallback: check individual consent flags
        let optOutSale = UserDefaults.standard.bool(forKey: "IABUSPrivacy_OptOutSale") ? "Y" : "N"
        let optOutSharing = UserDefaults.standard.bool(forKey: "IABUSPrivacy_OptOutSharing") ? "Y" : "N"
        let limitAdTracking = UserDefaults.standard.bool(forKey: "IABUSPrivacy_LimitAdTracking") ? "Y" : "N"
        
        // Format: 1--- (1=not applicable, ---=not set)
        return "1\(optOutSale)\(optOutSharing)\(limitAdTracking)"
    }
    
    public static var ccpa: String {
        // Try to get CCPA consent from UserDefaults
        if let ccpaConsent = UserDefaults.standard.string(forKey: "IABCCPA_Consent") {
            return ccpaConsent
        }
        
        // Fallback: check if user has opted out of sale
        let optOutSale = UserDefaults.standard.bool(forKey: "IABCCPA_OptOutSale")
        return optOutSale ? "1" : "0"
    }
    
    public static var coppa: String {
        // Try to get COPPA status from UserDefaults
        if let coppaStatus = UserDefaults.standard.string(forKey: "IABCOPPA_Status") {
            return coppaStatus
        }
        
        // Fallback: check if app is directed to children
        if let isChildDirected = UserDefaults.standard.object(forKey: "IABCOPPA_ChildDirected") as? Bool {
            return isChildDirected ? "1" : "0"
        }
        
        // Default to not child-directed
        return "0"
    }
    
    public static var debugInfo:[String: Any] {
        return [
            "bundleId": bundleId,
            "appName": appName,
            "appVersion": appVersion,
            "deviceWidth": deviceWidth,
            "deviceHeight": deviceHeight,
            "language": language,
            "userAgent": userAgent,
            "trackingEnabled": isTrackingEnabled,
            "advertisingId": advertisingIdentifier,
            "doNotTrack": doNotTrack,
            "systemVersion": UIDevice.current.systemVersion,
            "deviceModel": UIDevice.current.model
        ]
    }
}
