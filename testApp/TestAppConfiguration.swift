import Foundation

enum TestAppConfiguration {
    static let applovinSDKKey = string(for: "APPLOVIN_SDK_KEY")
        ?? plistString(for: "AppLovinSdkKey")
        ?? ""

    static let bannerAdUnitId = string(for: "MAX_BANNER_AD_UNIT_ID") ?? plistString(for: "MAX_BANNER_AD_UNIT_ID") ?? ""
    static let mrecAdUnitId = string(for: "MAX_MREC_AD_UNIT_ID") ?? plistString(for: "MAX_MREC_AD_UNIT_ID") ?? ""
    static let interstitialAdUnitId = string(for: "MAX_INTERSTITIAL_AD_UNIT_ID") ?? plistString(for: "MAX_INTERSTITIAL_AD_UNIT_ID") ?? ""
    static let rewardedAdUnitId = string(for: "MAX_REWARDED_AD_UNIT_ID") ?? plistString(for: "MAX_REWARDED_AD_UNIT_ID") ?? ""
    static let nativeAdUnitId = string(for: "MAX_NATIVE_AD_UNIT_ID") ?? plistString(for: "MAX_NATIVE_AD_UNIT_ID") ?? ""

    static let testSSPAuthority = string(for: "BIDSCUBE_TEST_SSP_AUTHORITY")
        ?? string(for: "bidcube.testSspAuthority")

    static var isMAXConfigured: Bool {
        !applovinSDKKey.isEmpty
    }

    static func applyOptionalSSPEnvironment() {
        guard let authority = testSSPAuthority, !authority.isEmpty else { return }
        setenv("bidcube.testSspAuthority", authority, 1)
    }

    private static func string(for key: String) -> String? {
        let value = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private static func plistString(for key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
