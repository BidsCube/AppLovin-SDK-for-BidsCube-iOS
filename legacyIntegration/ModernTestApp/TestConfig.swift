import Foundation

enum TestConfig {
    // MARK: - Bidscube SDK (direct)

    static let adRequestAuthority = configured("BIDSCUBE_AD_AUTHORITY")
        ?? configured("BIDSCUBE_TEST_SSP_AUTHORITY")
        ?? ""

    static let bannerPlacementId = configured("BIDSCUBE_BANNER_PLACEMENT_ID") ?? "20212"
    static let videoPlacementId = configured("BIDSCUBE_VIDEO_PLACEMENT_ID") ?? "20213"
    static let nativePlacementId = configured("BIDSCUBE_NATIVE_PLACEMENT_ID") ?? "20214"

    // MARK: - AppLovin MAX

    static let appLovinSdkKey = configured("APPLOVIN_SDK_KEY")
        ?? configured("AppLovinSdkKey")
        ?? ""

    static let bannerAdUnitId = configured("MAX_BANNER_AD_UNIT_ID") ?? ""
    static let mrecAdUnitId = configured("MAX_MREC_AD_UNIT_ID") ?? ""
    static let interstitialAdUnitId = configured("MAX_INTERSTITIAL_AD_UNIT_ID") ?? ""
    static let rewardedAdUnitId = configured("MAX_REWARDED_AD_UNIT_ID") ?? ""

    static var isMaxConfigured: Bool {
        !appLovinSdkKey.isEmpty
    }

    static var isMaxAdsConfigured: Bool {
        isMaxConfigured
            && !bannerAdUnitId.isEmpty
            && !mrecAdUnitId.isEmpty
            && !interstitialAdUnitId.isEmpty
            && !rewardedAdUnitId.isEmpty
    }

    static func applyOptionalSSPEnvironment() {
        guard !adRequestAuthority.isEmpty else { return }
        setenv("bidcube.testSspAuthority", adRequestAuthority, 1)
    }

    private static func configured(_ key: String) -> String? {
        if let value = env(key) { return value }
        return plist(key)
    }

    private static func env(_ key: String) -> String? {
        let value = ProcessInfo.processInfo.environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private static func plist(_ key: String) -> String? {
        let value = (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
