import Foundation
import UIKit

public struct URLBuilder {
    public static func normalizedAdRequestAuthority(from rawValue: String?) -> String {
        var authority = (rawValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if authority.isEmpty {
            return DeviceInfo.defaultAdRequestAuthority
        }

        for _ in 0..<3 {
            guard let decoded = authority.removingPercentEncoding, decoded != authority else { break }
            authority = decoded
        }

        let lowercased = authority.lowercased()
        if lowercased.hasPrefix("https://") {
            authority.removeFirst(8)
        } else if lowercased.hasPrefix("http://") {
            authority.removeFirst(7)
        }

        if let slashIndex = authority.firstIndex(of: "/") {
            authority = String(authority[..<slashIndex])
        }

        if let queryIndex = authority.firstIndex(of: "?") {
            authority = String(authority[..<queryIndex])
        }

        authority = authority.trimmingCharacters(in: .whitespacesAndNewlines)
        return authority.isEmpty ? DeviceInfo.defaultAdRequestAuthority : authority
    }

    public static func baseURLString(from authorityOrURL: String?) -> String {
        buildBaseURL(from: authorityOrURL)?.absoluteString ?? Constants.baseURL
    }

    public static func buildBaseURL(from authorityOrURL: String?) -> URL? {
        let authority = normalizedAdRequestAuthority(from: authorityOrURL)
        guard let endpoint = parseAuthority(authority) else {
            logError("Failed to parse ad request authority: \(authority)")
            return URL(string: Constants.baseURL)
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = endpoint.host
        components.port = endpoint.port
        components.path = Constants.sdkPath
        return components.url
    }

    public static func buildAdRequestURL(
        placementId: String,
        adType: AdType,
        position: AdPosition,
        timeoutMs: Int,
        debug: Bool,
        ctaText: String? = nil,
        includeSKAdNetworks: Bool = true,
        nativeWidth: Int? = nil,
        nativeHeight: Int? = nil
    ) -> URL? {
        return buildAdRequestURL(
            base: Constants.baseURL,
            placementId: placementId,
            adType: adType,
            position: position,
            timeoutMs: timeoutMs,
            debug: debug,
            ctaText: ctaText,
            includeSKAdNetworks: includeSKAdNetworks,
            nativeWidth: nativeWidth,
            nativeHeight: nativeHeight
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
        includeSKAdNetworks: Bool = true,
        nativeWidth: Int? = nil,
        nativeHeight: Int? = nil
    ) -> URL? {
        guard let baseURL = buildBaseURL(from: base),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            logError("Failed to create URL components from base: \(base)")
            return nil
        }

        var queryItems = buildQueryItems(
            placementId: placementId,
            adType: adType,
            nativeWidth: nativeWidth,
            nativeHeight: nativeHeight
        )

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

    private static func buildQueryItems(
        placementId: String,
        adType: AdType,
        nativeWidth: Int?,
        nativeHeight: Int?
    ) -> [URLQueryItem] {
        switch adType {
        case .image:
            return [
                URLQueryItem(name: Constants.QueryParams.placementId, value: placementId),
                URLQueryItem(name: Constants.QueryParams.contentType, value: Constants.AdTypes.image),
                URLQueryItem(name: Constants.QueryParams.method, value: Constants.Methods.api),
                URLQueryItem(name: Constants.QueryParams.response, value: Constants.ResponseFormats.js),
                URLQueryItem(name: Constants.QueryParams.app, value: "1"),
                URLQueryItem(name: Constants.QueryParams.bundle, value: DeviceInfo.bundleId),
                URLQueryItem(name: Constants.QueryParams.name, value: DeviceInfo.appName),
                URLQueryItem(name: Constants.QueryParams.appStoreURL, value: DeviceInfo.appStoreURL),
                URLQueryItem(name: Constants.QueryParams.language, value: DeviceInfo.language),
                URLQueryItem(name: Constants.QueryParams.deviceWidth, value: String(DeviceInfo.deviceWidth)),
                URLQueryItem(name: Constants.QueryParams.deviceHeight, value: String(DeviceInfo.deviceHeight)),
                URLQueryItem(name: Constants.QueryParams.userAgent, value: DeviceInfo.userAgent),
                URLQueryItem(name: Constants.QueryParams.advertisingId, value: DeviceInfo.advertisingIdentifier),
                URLQueryItem(name: Constants.QueryParams.doNotTrack, value: String(DeviceInfo.doNotTrack))
            ]

        case .video:
            return [
                URLQueryItem(name: Constants.QueryParams.contentType, value: Constants.AdTypes.video),
                URLQueryItem(name: Constants.QueryParams.method, value: Constants.Methods.xml),
                URLQueryItem(name: Constants.QueryParams.id, value: placementId),
                URLQueryItem(name: Constants.QueryParams.app, value: "1"),
                URLQueryItem(name: Constants.QueryParams.width, value: String(DeviceInfo.deviceWidth)),
                URLQueryItem(name: Constants.QueryParams.height, value: String(DeviceInfo.deviceHeight)),
                URLQueryItem(name: Constants.QueryParams.bundle, value: DeviceInfo.bundleId),
                URLQueryItem(name: Constants.QueryParams.name, value: DeviceInfo.appName),
                URLQueryItem(name: Constants.QueryParams.appVersion, value: DeviceInfo.appVersion),
                URLQueryItem(name: Constants.QueryParams.advertisingId, value: DeviceInfo.advertisingIdentifier),
                URLQueryItem(name: Constants.QueryParams.doNotTrack, value: String(DeviceInfo.doNotTrack)),
                URLQueryItem(name: Constants.QueryParams.appStoreURL, value: DeviceInfo.appStoreURL),
                URLQueryItem(name: Constants.QueryParams.userAgent, value: DeviceInfo.userAgent),
                URLQueryItem(name: Constants.QueryParams.language, value: DeviceInfo.language),
                URLQueryItem(name: Constants.QueryParams.deviceWidth, value: String(DeviceInfo.deviceWidth)),
                URLQueryItem(name: Constants.QueryParams.deviceHeight, value: String(DeviceInfo.deviceHeight))
            ]

        case .native:
            let requestWidth = nativeWidth ?? DeviceInfo.logicalScreenWidth
            let requestHeight = nativeHeight ?? DeviceInfo.logicalScreenHeight
            return [
                URLQueryItem(name: Constants.QueryParams.contentType, value: Constants.AdTypes.native),
                URLQueryItem(name: Constants.QueryParams.method, value: Constants.Methods.native),
                URLQueryItem(name: Constants.QueryParams.id, value: placementId),
                URLQueryItem(name: Constants.QueryParams.app, value: "1"),
                URLQueryItem(name: Constants.QueryParams.bundle, value: nullLiteralIfEmpty(DeviceInfo.bundleId)),
                URLQueryItem(name: Constants.QueryParams.name, value: nullLiteralIfEmpty(DeviceInfo.appName)),
                URLQueryItem(name: Constants.QueryParams.appVersion, value: nullLiteralIfEmpty(DeviceInfo.appVersion)),
                URLQueryItem(name: Constants.QueryParams.advertisingId, value: nullLiteralIfEmpty(DeviceInfo.advertisingIdentifier)),
                URLQueryItem(name: Constants.QueryParams.doNotTrack, value: String(DeviceInfo.doNotTrack)),
                URLQueryItem(name: Constants.QueryParams.appStoreURL, value: nullLiteralIfEmpty(DeviceInfo.appStoreURL)),
                URLQueryItem(name: Constants.QueryParams.userAgent, value: nullLiteralIfEmpty(DeviceInfo.userAgent)),
                URLQueryItem(name: Constants.Privacy.gdprKey, value: DeviceInfo.gdpr),
                URLQueryItem(name: Constants.Privacy.gdprConsentKey, value: nullLiteralIfEmpty(DeviceInfo.gdprConsent)),
                URLQueryItem(name: Constants.Privacy.usPrivacyKey, value: nullLiteralIfEmpty(DeviceInfo.usPrivacy)),
                URLQueryItem(name: Constants.Privacy.ccpaKey, value: DeviceInfo.ccpa),
                URLQueryItem(name: Constants.Privacy.coppaKey, value: DeviceInfo.coppa),
                URLQueryItem(name: Constants.QueryParams.language, value: nullLiteralIfEmpty(DeviceInfo.language)),
                URLQueryItem(name: Constants.QueryParams.deviceWidth, value: String(DeviceInfo.deviceWidth)),
                URLQueryItem(name: Constants.QueryParams.deviceHeight, value: String(DeviceInfo.deviceHeight)),
                URLQueryItem(name: Constants.QueryParams.width, value: String(requestWidth)),
                URLQueryItem(name: Constants.QueryParams.height, value: String(requestHeight))
            ]
        }
    }

    private static func nullLiteralIfEmpty(_ value: String?) -> String {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "null" : trimmed
    }

    private static func parseAuthority(_ authority: String) -> (host: String, port: Int?)? {
        let value = normalizedAdRequestAuthority(from: authority)

        if value.hasPrefix("[") {
            guard let closingBracket = value.firstIndex(of: "]") else {
                return (host: value, port: nil)
            }

            let hostStart = value.index(after: value.startIndex)
            let host = String(value[hostStart..<closingBracket])
            let remainder = value[value.index(after: closingBracket)...]
            if remainder.hasPrefix(":") {
                let portString = String(remainder.dropFirst())
                if isValidPort(portString) {
                    return (host: host, port: Int(portString))
                }
            }
            return (host: host, port: nil)
        }

        if let colonIndex = value.lastIndex(of: ":") {
            let hostPart = String(value[..<colonIndex])
            let portCandidate = String(value[value.index(after: colonIndex)...])
            if isValidPort(portCandidate), !hostPart.contains(":"), !hostPart.contains("]") {
                return (host: hostPart, port: Int(portCandidate))
            }
        }

        return (host: value, port: nil)
    }

    private static func isValidPort(_ candidate: String) -> Bool {
        guard (1...5).contains(candidate.count),
              candidate.allSatisfy({ $0.isNumber }),
              let port = Int(candidate),
              (0...65535).contains(port) else {
            return false
        }
        return true
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
