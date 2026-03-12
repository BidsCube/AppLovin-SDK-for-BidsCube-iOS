import Foundation


public struct Constants {

    public static let baseURL = "https://ssp-bcc-ads.com/sdk"
    public static let defaultTimeoutMs = 30000
    public static let defaultAdPosition = AdPosition.unknown
    
    public struct AdTypes {
        public static let image = "b"
        public static let video = "v"
        public static let native = "n"
    }
    
    public struct ResponseFormats {
        public static let json = "json"
        public static let js = "js"
        public static let xml = "xml"
    }
    
    
    public struct Methods {
        public static let api = "api"
        public static let xml = "xml"
    }
    
    public static let userAgentPrefix = "BidscubeSDK-iOS"
    public static let sdkVersion = "1.2.1"
    
    public struct ErrorCodes {
        public static let invalidURL = -1
        public static let networkError = -2
        public static let invalidResponse = -3
        public static let parsingError = -4
        public static let timeoutError = -5
        public static let consentError = -6
    }
    
    public struct ErrorMessages {
        public static let failedToBuildURL = "Failed to build request URL"
        public static let invalidResponse = "Invalid response"
        public static let networkError = "Network error occurred"
        public static let timeoutError = "Request timed out"
        public static let consentRequired = "User consent required"
        public static let sdkNotInitialized = "SDK not initialized"
    }
    
    public struct LogPrefixes {
        public static let sdk = "📱 BidscubeSDK"
        public static let urlBuilder = "🔗 URLBuilder"
        public static let network = "🌐 Network"
        public static let imageAd = "🖼️ ImageAd"
        public static let videoAd = "🎥 VideoAd"
        public static let nativeAd = "📱 NativeAd"
        public static let error = "Error:"
        public static let success = ""
        public static let info = "Info:"
    }
    
    public struct Animation {
        public static let defaultDuration: TimeInterval = 0.3
        public static let fastDuration: TimeInterval = 0.2
        public static let slowDuration: TimeInterval = 0.5
    }
    
    public struct Layout {
        public static let defaultMargin: CGFloat = 16
        public static let buttonSize: CGFloat = 40
        public static let cornerRadius: CGFloat = 8
        public static let borderWidth: CGFloat = 1
    }
    
    public struct Privacy {
        public static let gdprKey = "gdpr"
        public static let gdprConsentKey = "gdpr_consent"
        public static let usPrivacyKey = "us_privacy"
        public static let ccpaKey = "ccpa"
        public static let coppaKey = "coppa"
        public static let dntKey = "dnt"
        public static let ifaKey = "ifa"
    }
    
    
    public struct QueryParams {
        public static let placementId = "placementId"
        public static let id = "id"
        public static let contentType = "c"
        public static let method = "m"
        public static let response = "res"
        public static let app = "app"
        public static let bundle = "bundle"
        public static let name = "name"
        public static let appStoreURL = "app_store_url"
        public static let language = "language"
        public static let deviceWidth = "deviceWidth"
        public static let deviceHeight = "deviceHeight"
        public static let width = "w"
        public static let height = "h"
        public static let userAgent = "ua"
        public static let advertisingId = "ifa"
        public static let doNotTrack = "dnt"
        public static let appVersion = "app_version"
        public static let ctaText = "cta_text"
    }
}





