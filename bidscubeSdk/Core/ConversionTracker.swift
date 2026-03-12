import Foundation

/// Tracks conversion values for SKAdNetwork post-install attribution
@available(iOS 14.0, *)
public class ConversionTracker {
    
    // MARK: - Properties
    
    private static var currentValue: Int = 0
    private static var maxValue: Int = 63
    private static var trackedEvents: Set<String> = []
    
    // MARK: - Conversion Value Mapping
    
    /// Predefined conversion values for common events
    public struct ConversionValues {
        public static let adImpression: Int = 1
        public static let adClick: Int = 2
        public static let appOpen: Int = 3
        public static let userRegistration: Int = 5
        public static let firstPurchase: Int = 10
        public static let subscription: Int = 15
        public static let highValuePurchase: Int = 20
        public static let retention: Int = 25
        public static let engagement: Int = 30
        public static let premiumFeature: Int = 35
        public static let socialShare: Int = 40
        public static let referral: Int = 45
        public static let loyaltyProgram: Int = 50
        public static let premiumSubscription: Int = 55
        public static let maxValue: Int = 63
    }
    
    // MARK: - Public Methods
    
    /// Track a specific conversion event
    /// - Parameters:
    ///   - event: The event name
    ///   - value: The conversion value (0-63)
    public static func trackEvent(_ event: String, value: Int) {
        let clampedValue = max(0, min(value, maxValue))
        
        // Only update if the new value is higher
        guard clampedValue > currentValue else {
            print("📱 BidscubeSDK: Conversion value \(clampedValue) not higher than current \(currentValue)")
            return
        }
        
        // Check if we've already tracked this event
        if trackedEvents.contains(event) {
            print("📱 BidscubeSDK: Event '\(event)' already tracked")
            return
        }
        
        SKAdNetworkManager.updateConversionValue(clampedValue)
        currentValue = clampedValue
        trackedEvents.insert(event)
        
        print("📱 BidscubeSDK: Conversion event '\(event)' tracked with value \(clampedValue)")
    }
    
    /// Track ad impression
    public static func trackAdImpression() {
        trackEvent("ad_impression", value: ConversionValues.adImpression)
    }
    
    /// Track ad click
    public static func trackAdClick() {
        trackEvent("ad_click", value: ConversionValues.adClick)
    }
    
    /// Track app open
    public static func trackAppOpen() {
        trackEvent("app_open", value: ConversionValues.appOpen)
    }
    
    /// Track user registration
    public static func trackUserRegistration() {
        trackEvent("user_registration", value: ConversionValues.userRegistration)
    }
    
    /// Track first purchase
    public static func trackFirstPurchase() {
        trackEvent("first_purchase", value: ConversionValues.firstPurchase)
    }
    
    /// Track subscription
    public static func trackSubscription() {
        trackEvent("subscription", value: ConversionValues.subscription)
    }
    
    /// Track high value purchase
    public static func trackHighValuePurchase() {
        trackEvent("high_value_purchase", value: ConversionValues.highValuePurchase)
    }
    
    /// Track user retention (e.g., 7-day retention)
    public static func trackRetention() {
        trackEvent("retention", value: ConversionValues.retention)
    }
    
    /// Track user engagement
    public static func trackEngagement() {
        trackEvent("engagement", value: ConversionValues.engagement)
    }
    
    /// Track premium feature usage
    public static func trackPremiumFeature() {
        trackEvent("premium_feature", value: ConversionValues.premiumFeature)
    }
    
    /// Track social share
    public static func trackSocialShare() {
        trackEvent("social_share", value: ConversionValues.socialShare)
    }
    
    /// Track referral
    public static func trackReferral() {
        trackEvent("referral", value: ConversionValues.referral)
    }
    
    /// Track loyalty program participation
    public static func trackLoyaltyProgram() {
        trackEvent("loyalty_program", value: ConversionValues.loyaltyProgram)
    }
    
    /// Track premium subscription
    public static func trackPremiumSubscription() {
        trackEvent("premium_subscription", value: ConversionValues.premiumSubscription)
    }
    
    /// Get current conversion value
    public static func getCurrentValue() -> Int {
        return currentValue
    }
    
    /// Get tracked events
    public static func getTrackedEvents() -> Set<String> {
        return trackedEvents
    }
    
    /// Reset conversion tracking (useful for testing)
    public static func reset() {
        currentValue = 0
        trackedEvents.removeAll()
        print("📱 BidscubeSDK: Conversion tracking reset")
    }
    
    /// Check if an event has been tracked
    public static func hasTrackedEvent(_ event: String) -> Bool {
        return trackedEvents.contains(event)
    }
}

// MARK: - Pre-iOS 14 Compatibility

/// Fallback implementation for iOS versions before 14.0
public class ConversionTrackerLegacy {
    
    public static func trackEvent(_ event: String, value: Int) {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackAdImpression() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackAdClick() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackAppOpen() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackUserRegistration() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackFirstPurchase() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackSubscription() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackHighValuePurchase() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackRetention() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackEngagement() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackPremiumFeature() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackSocialShare() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackReferral() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackLoyaltyProgram() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func trackPremiumSubscription() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func getCurrentValue() -> Int {
        return 0
    }
    
    public static func getTrackedEvents() -> Set<String> {
        return []
    }
    
    public static func reset() {
        Logger.info("Conversion tracking not available on this iOS version")
    }
    
    public static func hasTrackedEvent(_ event: String) -> Bool {
        return false
    }
}
