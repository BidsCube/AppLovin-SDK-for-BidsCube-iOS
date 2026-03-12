import Foundation
import UIKit

public final class SDKConfig {
    public let enableLogging: Bool
    public let enableDebugMode: Bool
    public let defaultAdTimeoutMs: Int
    public let defaultAdPosition: AdPosition
    public let baseURL: String
    public let enableSKAdNetwork: Bool
    public let skAdNetworkId: String?
    public let skAdNetworkConversionValue: Int

    private init(enableLogging: Bool,
                 enableDebugMode: Bool,
                 defaultAdTimeoutMs: Int,
                 defaultAdPosition: AdPosition,
                 baseURL: String,
                 enableSKAdNetwork: Bool,
                 skAdNetworkId: String?,
                 skAdNetworkConversionValue: Int,
) {
        self.enableLogging = enableLogging
        self.enableDebugMode = enableDebugMode
        self.defaultAdTimeoutMs = defaultAdTimeoutMs
        self.defaultAdPosition = defaultAdPosition
        self.baseURL = baseURL
        self.enableSKAdNetwork = enableSKAdNetwork
        self.skAdNetworkId = skAdNetworkId
        self.skAdNetworkConversionValue = skAdNetworkConversionValue
    }

    public final class Builder {
        private var enableLogging: Bool = true
        private var enableDebugMode: Bool = false
        private var defaultAdTimeoutMs: Int = 30000
        private var defaultAdPosition: AdPosition = .unknown
        private var baseURL: String = Constants.baseURL
        private var enableSKAdNetwork: Bool = false
        private var skAdNetworkId: String? = nil
        private var skAdNetworkConversionValue: Int = 0

        public init() {}

        @discardableResult
        public func enableLogging(_ value: Bool) -> Builder {
            self.enableLogging = value
            return self
        }

        @discardableResult
        public func enableDebugMode(_ value: Bool) -> Builder {
            self.enableDebugMode = value
            return self
        }

        @discardableResult
        public func defaultAdTimeout(_ millis: Int) -> Builder {
            self.defaultAdTimeoutMs = millis
            return self
        }

        @discardableResult
        public func defaultAdPosition(_ position: AdPosition) -> Builder {
            self.defaultAdPosition = position
            return self
        }

        @discardableResult
        public func baseURL(_ url: String) -> Builder {
            self.baseURL = url
            return self
        }

        @discardableResult
        public func enableSKAdNetwork(_ value: Bool) -> Builder {
            self.enableSKAdNetwork = value
            return self
        }

        @discardableResult
        public func skAdNetworkId(_ id: String?) -> Builder {
            self.skAdNetworkId = id
            return self
        }

        @discardableResult
        public func skAdNetworkConversionValue(_ value: Int) -> Builder {
            self.skAdNetworkConversionValue = max(0, min(value, 63))
            return self
        }
        

        public func build() -> SDKConfig {
            SDKConfig(
                enableLogging: enableLogging,
                enableDebugMode: enableDebugMode,
                defaultAdTimeoutMs: defaultAdTimeoutMs,
                defaultAdPosition: defaultAdPosition,
                baseURL: baseURL,
                enableSKAdNetwork: enableSKAdNetwork,
                skAdNetworkId: skAdNetworkId,
                skAdNetworkConversionValue: skAdNetworkConversionValue,
            )
        }
    }

    public static var detectedAppId: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    public static var detectedAppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }

    public static var detectedAppVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }

    public static var detectedLanguage: String {
        Locale.preferredLanguages.first ?? Locale.current.identifier
    }

    public static var detectedUserAgent: String {
        let systemVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        return "BidscubeSDK-iOS/1.0 (iOS \(systemVersion); \(model))"
    }
}



