import Foundation
import StoreKit

/// Manager for handling SKAdNetwork attribution and conversion tracking
@available(iOS 14.0, *)
public class SKAdNetworkManager {
    
    // MARK: - Properties
    
    private static var isRegistered = false
    private static var currentConversionValue: Int = 0
    private static var maxConversionValue: Int = 63
    
    // MARK: - Public Methods
    
    /// Register the app for ad network attribution
    /// This should be called at app launch
    public static func registerForAdNetworkAttribution() {
        guard !isRegistered else {
            Logger.info("SKAdNetwork already registered")
            return
        }
        
        SKAdNetwork.registerAppForAdNetworkAttribution()
        isRegistered = true
        Logger.info("SKAdNetwork registered for attribution")
    }
    
    /// Update the conversion value for post-install attribution
    /// - Parameter value: Conversion value (0-63)
    public static func updateConversionValue(_ value: Int) {
        let clampedValue = max(0, min(value, maxConversionValue))
        
        guard clampedValue > currentConversionValue else {
            Logger.debug("Conversion value \(clampedValue) not higher than current \(currentConversionValue)")
            return
        }
        
        SKAdNetwork.updateConversionValue(clampedValue)
        currentConversionValue = clampedValue
        Logger.info("SKAdNetwork conversion value updated to \(clampedValue)")
    }
    
    /// Get the current conversion value
    public static func getCurrentConversionValue() -> Int {
        return currentConversionValue
    }
    
    /// Reset conversion value (useful for testing)
    public static func resetConversionValue() {
        currentConversionValue = 0
        Logger.info("SKAdNetwork conversion value reset")
    }
    
    /// Check if SKAdNetwork is available
    public static func isAvailable() -> Bool {
        return true
    }
    
    /// Get SKAdNetwork attribution status
    public static func getAttributionStatus() -> String {
        return isRegistered ? "registered" : "not_registered"
    }
    
    // MARK: - Conversion Value Helpers
    
    /// Update conversion value for ad impression
    public static func trackAdImpression() {
        updateConversionValue(currentConversionValue + 1)
    }
    
    /// Update conversion value for ad click
    public static func trackAdClick() {
        updateConversionValue(currentConversionValue + 2)
    }
    
    /// Update conversion value for app install
    public static func trackAppInstall() {
        updateConversionValue(currentConversionValue + 5)
    }
    
    /// Update conversion value for in-app purchase
    public static func trackInAppPurchase() {
        updateConversionValue(currentConversionValue + 10)
    }
    
    /// Update conversion value for subscription
    public static func trackSubscription() {
        updateConversionValue(currentConversionValue + 15)
    }
    
    /// Read all SKAdNetwork IDs from the app's Info.plist
    /// - Returns: Array of SKAdNetwork identifiers
    public static func getSKAdNetworkIDs() -> [String] {
        var identifiers: [String] = []
        
        // Try to get SKAdNetworkItems from Bundle.main.infoDictionary first
        if let infoDict = Bundle.main.infoDictionary {
            print("SKAdNetwork: Checking Bundle.main.infoDictionary for SKAdNetworkItems")
            
            if let skAdNetworkItems = infoDict["SKAdNetworkItems"] as? [[String: Any]] {
                print("SKAdNetwork: Found SKAdNetworkItems array with \(skAdNetworkItems.count) items")
                
                identifiers = skAdNetworkItems.compactMap { item in
                    guard let identifier = item["SKAdNetworkIdentifier"] as? String else {
                        print("SKAdNetwork: Warning - item missing SKAdNetworkIdentifier: \(item)")
                        return nil
                    }
                    return identifier
                }
                
                print("SKAdNetwork: Successfully extracted \(identifiers.count) SKAdNetwork identifiers from Bundle.main.infoDictionary")
                return identifiers
            } else {
                print("SKAdNetwork: SKAdNetworkItems not found in Bundle.main.infoDictionary")
                print("SKAdNetwork: Available keys in infoDictionary: \(Array(infoDict.keys).sorted())")
            }
        } else {
            print("SKAdNetwork: Bundle.main.infoDictionary is nil")
        }
        
        // Fallback: try to read from Info.plist file directly
        print("SKAdNetwork: Attempting to read Info.plist file directly")
        
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist") else {
            print("SKAdNetwork: Could not find Info.plist file path")
            return []
        }
        
        print("SKAdNetwork: Found Info.plist at path: \(path)")
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            print("SKAdNetwork: Could not read Info.plist file as NSDictionary")
            return []
        }
        
        print("SKAdNetwork: Successfully loaded Info.plist file")
        print("SKAdNetwork: Available keys in Info.plist: \(Array(plist.allKeys as! [String]).sorted())")
        
        guard let skAdNetworkItems = plist["SKAdNetworkItems"] as? [[String: Any]] else {
            print("SKAdNetwork: SKAdNetworkItems not found in Info.plist or not in expected format")
            if let skAdNetworkItemsRaw = plist["SKAdNetworkItems"] {
                print("SKAdNetwork: SKAdNetworkItems found but wrong type: \(type(of: skAdNetworkItemsRaw))")
                print("SKAdNetwork: SKAdNetworkItems content: \(skAdNetworkItemsRaw)")
            }
            return []
        }
        
        print("SKAdNetwork: Found SKAdNetworkItems array with \(skAdNetworkItems.count) items in Info.plist")
        
        identifiers = skAdNetworkItems.compactMap { item in
            guard let identifier = item["SKAdNetworkIdentifier"] as? String else {
                print("SKAdNetwork: Warning - item missing SKAdNetworkIdentifier: \(item)")
                return nil
            }
            return identifier
        }
        
        print("SKAdNetwork: Successfully extracted \(identifiers.count) SKAdNetwork identifiers from Info.plist file")
        return identifiers
    }
    
    /// Display SKAdNetwork IDs in console
    public static func displaySKAdNetworkIDsInConsole() {
        let identifiers = getSKAdNetworkIDs()
        
        print("\n" + String(repeating: "=", count: 50))
        print("SKAdNetwork IDs from Info.plist:")
        print(String(repeating: "=", count: 50))
        
        if identifiers.isEmpty {
            print("No SKAdNetwork identifiers found in Info.plist")
        } else {
            for (index, identifier) in identifiers.enumerated() {
                print("[\(index + 1)] \(identifier)")
            }
        }
        
        print("Total: \(identifiers.count) identifiers")
        print(String(repeating: "=", count: 50) + "\n")
    }
    
    /// Get SKAdNetwork IDs as formatted string for display
    /// - Returns: Formatted string with all SKAdNetwork IDs
    public static func getSKAdNetworkIDsAsString() -> String {
        let identifiers = getSKAdNetworkIDs()
        
        if identifiers.isEmpty {
            return "No SKAdNetwork identifiers found in Info.plist"
        }
        
        var result = "SKAdNetwork IDs (\(identifiers.count) total):\n\n"
        
        for (index, identifier) in identifiers.enumerated() {
            result += "[\(index + 1)] \(identifier)\n"
        }
        
        return result
    }
    
    /// Debug method to inspect Info.plist structure
    /// - Returns: Detailed information about Info.plist contents
    public static func debugInfoPlistStructure() -> String {
        var result = "=== Info.plist Debug Information ===\n\n"
        
        // Check Bundle.main.infoDictionary
        if let infoDict = Bundle.main.infoDictionary {
            result += "Bundle.main.infoDictionary available: YES\n"
            result += "Keys in infoDictionary: \(Array(infoDict.keys).sorted())\n\n"
            
            if let skAdNetworkItems = infoDict["SKAdNetworkItems"] {
                result += "SKAdNetworkItems found in infoDictionary: YES\n"
                result += "Type: \(type(of: skAdNetworkItems))\n"
                result += "Content: \(skAdNetworkItems)\n\n"
            } else {
                result += "SKAdNetworkItems found in infoDictionary: NO\n\n"
            }
        } else {
            result += "Bundle.main.infoDictionary available: NO\n\n"
        }
        
        // Check Info.plist file directly
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            result += "Info.plist file path: \(path)\n"
            
            if let plist = NSDictionary(contentsOfFile: path) {
                result += "Info.plist file readable: YES\n"
                result += "Keys in Info.plist: \(Array(plist.allKeys as! [String]).sorted())\n\n"
                
                if let skAdNetworkItems = plist["SKAdNetworkItems"] {
                    result += "SKAdNetworkItems found in Info.plist: YES\n"
                    result += "Type: \(type(of: skAdNetworkItems))\n"
                    result += "Content: \(skAdNetworkItems)\n\n"
                } else {
                    result += "SKAdNetworkItems found in Info.plist: NO\n\n"
                }
            } else {
                result += "Info.plist file readable: NO\n\n"
            }
        } else {
            result += "Info.plist file path: NOT FOUND\n\n"
        }
        
        result += "=== End Debug Information ==="
        return result
    }
    
    /// Parse SKAdNetwork response from JSON
    /// - Parameter json: The JSON object containing SKAdNetwork data
    /// - Returns: Parsed SKAdNetwork response or nil if parsing fails
    public static func parseSKAdNetworkResponse(from json: [String: Any]) -> SKAdNetworkResponse? {
        guard let version = json["version"] as? String else {
            Logger.error("SKAdNetwork: Missing version field")
            return nil
        }
        
        Logger.info("SKAdNetwork: Parsing response with version: \(version)")
        
        // Check if this is v2.16.0+ (has fidelities object)
        if json["fidelities"] != nil {
            return parseV2_16Response(from: json)
        } else {
            return parseV2_15Response(from: json)
        }
    }
    
    private static func parseV2_15Response(from json: [String: Any]) -> SKAdNetworkResponse? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            let response = try JSONDecoder().decode(SKAdNetworkResponseV2_15.self, from: data)
            Logger.info("SKAdNetwork: Successfully parsed v2.15 response")
            return .version2_15(response)
        } catch {
            Logger.error("SKAdNetwork: Failed to parse v2.15 response: \(error)")
            return nil
        }
    }
    
    private static func parseV2_16Response(from json: [String: Any]) -> SKAdNetworkResponse? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            let response = try JSONDecoder().decode(SKAdNetworkResponseV2_16.self, from: data)
            Logger.info("SKAdNetwork: Successfully parsed v2.16 response with \(response.fidelities.count) fidelities")
            return .version2_16(response)
        } catch {
            Logger.error("SKAdNetwork: Failed to parse v2.16 response: \(error)")
            return nil
        }
    }
    
    /// Process SKAdNetwork response for tracking
    /// - Parameter response: The parsed SKAdNetwork response
    public static func processSKAdNetworkResponse(_ response: SKAdNetworkResponse) {
        Logger.info("SKAdNetwork: Processing response for network: \(response.network)")
        
        switch response {
        case .version2_15(let v2_15Response):
            processV2_15Response(v2_15Response)
        case .version2_16(let v2_16Response):
            processV2_16Response(v2_16Response)
        }
    }
    
    private static func processV2_15Response(_ response: SKAdNetworkResponseV2_15) {
        Logger.info("SKAdNetwork v2.15: Network=\(response.network), Campaign=\(response.campaign), iTunesItem=\(response.itunesitem)")
        Logger.info("SKAdNetwork v2.15: Nonce=\(response.nonce), Timestamp=\(response.timestamp)")
        
        trackSKAdNetworkEvent(
            network: response.network,
            campaign: response.campaign,
            itunesitem: response.itunesitem,
            nonce: response.nonce,
            timestamp: response.timestamp,
            signature: response.signature,
            fidelityType: response.fidelityType
        )
    }
    
    private static func processV2_16Response(_ response: SKAdNetworkResponseV2_16) {
        Logger.info("SKAdNetwork v2.16: Network=\(response.network), Campaign=\(response.campaign), iTunesItem=\(response.itunesitem)")
        Logger.info("SKAdNetwork v2.16: Processing \(response.fidelities.count) fidelities")
        
        for (index, fidelity) in response.fidelities.enumerated() {
            Logger.info("SKAdNetwork v2.16: Fidelity \(index): Type=\(fidelity.fidelity.rawValue), Nonce=\(fidelity.nonce)")
            
            trackSKAdNetworkEvent(
                network: response.network,
                campaign: response.campaign,
                itunesitem: response.itunesitem,
                nonce: fidelity.nonce,
                timestamp: fidelity.timestamp,
                signature: fidelity.signature,
                fidelityType: fidelity.fidelity
            )
        }
    }
    
    private static func trackSKAdNetworkEvent(
        network: String,
        campaign: Int,
        itunesitem: Int64,
        nonce: String,
        timestamp: Int64,
        signature: String,
        fidelityType: SKAdNetworkFidelityType?
    ) {
        Logger.info("SKAdNetwork: Tracking event for network: \(network)")
        Logger.info("SKAdNetwork: Would track - Network: \(network), Campaign: \(campaign), iTunesItem: \(itunesitem)")
        Logger.info("SKAdNetwork: Would track - Nonce: \(nonce), Timestamp: \(timestamp)")
        if let fidelityType = fidelityType {
            Logger.info("SKAdNetwork: Would track - FidelityType: \(fidelityType.rawValue)")
        }
    }
}

// MARK: - Pre-iOS 14 Compatibility

/// Fallback implementation for iOS versions before 14.0
public class SKAdNetworkManagerLegacy {
    
    public static func registerForAdNetworkAttribution() {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func updateConversionValue(_ value: Int) {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func getCurrentConversionValue() -> Int {
        return 0
    }
    
    public static func resetConversionValue() {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func isAvailable() -> Bool {
        return false
    }
    
    public static func getAttributionStatus() -> String {
        return "not_available"
    }
    
    public static func trackAdImpression() {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func trackAdClick() {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func trackAppInstall() {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func trackInAppPurchase() {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func trackSubscription() {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func getSKAdNetworkIDs() -> [String] {
        Logger.info("SKAdNetwork not available on this iOS version")
        return []
    }
    
    public static func displaySKAdNetworkIDsInConsole() {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
    
    public static func getSKAdNetworkIDsAsString() -> String {
        Logger.info("SKAdNetwork not available on this iOS version")
        return "SKAdNetwork not available on this iOS version"
    }
    
    public static func debugInfoPlistStructure() -> String {
        Logger.info("SKAdNetwork not available on this iOS version")
        return "SKAdNetwork not available on this iOS version"
    }
    
    /// Parse SKAdNetwork response from JSON (stub for legacy iOS versions)
    /// - Parameter json: The JSON object containing SKAdNetwork data
    /// - Returns: nil (SKAdNetwork not available on this iOS version)
    public static func parseSKAdNetworkResponse(from json: [String: Any]) -> SKAdNetworkResponse? {
        Logger.info("SKAdNetwork not available on this iOS version")
        return nil
    }
    
    /// Process SKAdNetwork response for tracking (stub for legacy iOS versions)
    /// - Parameter response: The parsed SKAdNetwork response
    public static func processSKAdNetworkResponse(_ response: SKAdNetworkResponse) {
        Logger.info("SKAdNetwork not available on this iOS version")
    }
}
