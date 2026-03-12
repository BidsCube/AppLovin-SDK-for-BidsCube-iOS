import Foundation
import UIKit

public struct URLBuilder {
    public static func buildAdRequestURL(
        placementId: String,
        adType: AdType,
        position: AdPosition,
        timeoutMs: Int,
        debug: Bool,
        ctaText: String? = nil,
        includeSKAdNetworks: Bool = true
    ) -> URL? {
        return buildAdRequestURL(
            base: Constants.baseURL,
            placementId: placementId,
            adType: adType,
            position: position,
            timeoutMs: timeoutMs,
            debug: debug,
            ctaText: ctaText,
            includeSKAdNetworks: includeSKAdNetworks
        )
    }

    public static func buildAdRequestURL(
        base: String,
        placementId: String,
        adType: AdType,
        position: AdPosition,
        timeoutMs: Int,
        debug: Bool,
        ctaText: String? = nil,
        includeSKAdNetworks: Bool = true
    ) -> URL? {
        guard var components = URLComponents(string: base) else {
            logError("Failed to create URL components from base: \(base)")
            return nil
        }

        var queryItems = buildCommonQueryItems(placementId: placementId, adType: adType)
        queryItems.append(contentsOf: buildPrivacyQueryItems())

        if let ctaText = ctaText {
            queryItems.append(URLQueryItem(name: Constants.QueryParams.ctaText, value: ctaText))
        }
        
        // Add SKAdNetwork IDs as GET parameters
        if includeSKAdNetworks {
            let skAdNetworkIds = getSKAdNetworkIDsFromInfoPlist()
            for skAdNetworkId in skAdNetworkIds {
                queryItems.append(URLQueryItem(name: "skadnet", value: skAdNetworkId))
            }
            if !skAdNetworkIds.isEmpty {
                logSuccess("Added \(skAdNetworkIds.count) SKAdNetwork IDs as GET parameters")
            }
        }
        
        components.queryItems = queryItems

        guard let finalURL = components.url else {
            logError("Failed to construct final URL")
            return nil
        }

        logSuccess("Built \(adType.rawValue) ad URL: \(finalURL.absoluteString)")
        return finalURL
    }

    private static func buildCommonQueryItems(placementId: String, adType: AdType) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        items.append(URLQueryItem(name: Constants.QueryParams.placementId, value: placementId))
        
        items.append(contentsOf: buildAdTypeSpecificQueryItems(adType: adType, placementId: placementId))
        
        // Add common app info
        items.append(URLQueryItem(name: Constants.QueryParams.app, value: "1"))
        items.append(URLQueryItem(name: Constants.QueryParams.bundle, value: DeviceInfo.bundleId))
        items.append(URLQueryItem(name: Constants.QueryParams.name, value: DeviceInfo.appName))
        items.append(URLQueryItem(name: Constants.QueryParams.appStoreURL, value: DeviceInfo.appStoreURL))
        items.append(URLQueryItem(name: Constants.QueryParams.language, value: DeviceInfo.language))
        items.append(URLQueryItem(name: Constants.QueryParams.deviceWidth, value: String(DeviceInfo.deviceWidth)))
        items.append(URLQueryItem(name: Constants.QueryParams.deviceHeight, value: String(DeviceInfo.deviceHeight)))
        items.append(URLQueryItem(name: Constants.QueryParams.userAgent, value: DeviceInfo.userAgent))
        items.append(URLQueryItem(name: Constants.QueryParams.advertisingId, value: DeviceInfo.advertisingIdentifier))
        items.append(URLQueryItem(name: Constants.QueryParams.doNotTrack, value: String(DeviceInfo.doNotTrack)))

        return items
    }

    private static func buildAdTypeSpecificQueryItems(adType: AdType, placementId: String) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        switch adType {
        case .image:
            items.append(URLQueryItem(name: Constants.QueryParams.contentType, value: Constants.AdTypes.image))
            items.append(URLQueryItem(name: Constants.QueryParams.method, value: Constants.Methods.api))
            items.append(URLQueryItem(name: Constants.QueryParams.response, value: Constants.ResponseFormats.js))

        case .video:
            items.append(URLQueryItem(name: Constants.QueryParams.id, value: placementId))
            items.append(URLQueryItem(name: Constants.QueryParams.contentType, value: Constants.AdTypes.video))
            items.append(URLQueryItem(name: Constants.QueryParams.method, value: Constants.Methods.xml))
            items.append(URLQueryItem(name: Constants.QueryParams.width, value: String(DeviceInfo.deviceWidth)))
            items.append(URLQueryItem(name: Constants.QueryParams.height, value: String(DeviceInfo.deviceHeight)))
            items.append(URLQueryItem(name: Constants.QueryParams.appVersion, value: DeviceInfo.appVersion))

        case .native:
            items.append(URLQueryItem(name: Constants.QueryParams.contentType, value: Constants.AdTypes.native))
            items.append(URLQueryItem(name: Constants.QueryParams.method, value: Constants.Methods.api))
            items.append(URLQueryItem(name: Constants.QueryParams.response, value: Constants.ResponseFormats.json))
        }

        return items
    }

    private static func buildPrivacyQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        items.append(URLQueryItem(name: Constants.Privacy.gdprKey, value: DeviceInfo.gdpr))
        items.append(URLQueryItem(name: Constants.Privacy.gdprConsentKey, value: DeviceInfo.gdprConsent))
        items.append(URLQueryItem(name: Constants.Privacy.usPrivacyKey, value: DeviceInfo.usPrivacy))
        items.append(URLQueryItem(name: Constants.Privacy.ccpaKey, value: DeviceInfo.ccpa))
        items.append(URLQueryItem(name: Constants.Privacy.coppaKey, value: DeviceInfo.coppa))

        return items
    }
    

    private static func logSuccess(_ message: String) {
        Logger.urlBuilder(message)
    }

    private static func logError(_ message: String) {
        Logger.error(message, prefix: Constants.LogPrefixes.urlBuilder)
    }
    
    // MARK: - POST Request Body Builder
    
    /// Builds the request body for POST ad requests - contains only SKAdNetwork IDs
    /// - Parameters:
    ///   - placementId: The placement ID
    ///   - adType: The ad type
    ///   - position: The ad position
    ///   - timeoutMs: Request timeout in milliseconds
    ///   - debug: Debug mode flag
    ///   - ctaText: Optional CTA text
    ///   - includeSKAdNetworks: Whether to include SKAdNetwork data from Info.plist
    /// - Returns: Array of SKAdNetwork IDs or empty array
    public static func buildAdRequestBody(
        placementId: String,
        adType: AdType,
        position: AdPosition,
        timeoutMs: Int,
        debug: Bool,
        ctaText: String? = nil,
        includeSKAdNetworks: Bool = true
    ) -> [String] {
        Logger.info("🔧 URLBuilder.buildAdRequestBody called with includeSKAdNetworks: \(includeSKAdNetworks)")
        
        // Return only SKAdNetwork IDs from Info.plist
        if includeSKAdNetworks {
            let skAdNetworkIds = getSKAdNetworkIDsFromInfoPlist()
            if !skAdNetworkIds.isEmpty {
                logSuccess("Included \(skAdNetworkIds.count) SKAdNetwork IDs in request body: \(skAdNetworkIds)")
                return skAdNetworkIds
            } else {
                logSuccess("No SKAdNetwork IDs found in Info.plist")
                return []
            }
        } else {
            logSuccess("SKAdNetwork IDs excluded from request body (includeSKAdNetworks = false)")
            return []
        }
    }
    
    /// Extracts SKAdNetwork IDs from Info.plist
    /// - Returns: Array of SKAdNetwork identifiers
    private static func getSKAdNetworkIDsFromInfoPlist() -> [String] {
        Logger.info("🔍 getSKAdNetworkIDsFromInfoPlist called")
        var identifiers: [String] = []
        
        // Try to get SKAdNetworkItems from Bundle.main.infoDictionary first
        if let infoDict = Bundle.main.infoDictionary {
            Logger.info("📱 Bundle.main.infoDictionary available")
            if let skAdNetworkItems = infoDict["SKAdNetworkItems"] as? [[String: Any]] {
                Logger.info("✅ Found SKAdNetworkItems in infoDictionary: \(skAdNetworkItems.count) items")
                identifiers = skAdNetworkItems.compactMap { item in
                    guard let identifier = item["SKAdNetworkIdentifier"] as? String else {
                        return nil
                    }
                    return identifier
                }
            } else {
                Logger.info("❌ No SKAdNetworkItems found in infoDictionary")
            }
        } else {
            Logger.info("❌ Bundle.main.infoDictionary is nil")
        }
        
        // Fallback: try to read from Info.plist file directly
        if identifiers.isEmpty {
            Logger.info("🔄 Trying to read Info.plist file directly")
            guard let path = Bundle.main.path(forResource: "Info", ofType: "plist") else {
                Logger.info("❌ Could not find Info.plist file path")
                return []
            }
            
            Logger.info("📁 Info.plist path: \(path)")
            guard let plist = NSDictionary(contentsOfFile: path) else {
                Logger.info("❌ Could not read Info.plist file")
                return []
            }
            
            guard let skAdNetworkItems = plist["SKAdNetworkItems"] as? [[String: Any]] else {
                Logger.info("❌ No SKAdNetworkItems found in Info.plist file")
                return []
            }
            
            Logger.info("✅ Found SKAdNetworkItems in Info.plist file: \(skAdNetworkItems.count) items")
            identifiers = skAdNetworkItems.compactMap { item in
                guard let identifier = item["SKAdNetworkIdentifier"] as? String else {
                    return nil
                }
                return identifier
            }
        }
        
        Logger.info("🎯 Final result: \(identifiers.count) SKAdNetwork IDs: \(identifiers)")
        return identifiers
    }
}
