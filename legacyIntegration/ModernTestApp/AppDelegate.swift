import AppLovinSDK
import BidscubeSDK
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        initializeBidscubeSDK()
        initializeAppLovinMAX()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func initializeBidscubeSDK() {
        TestConfig.applyOptionalSSPEnvironment()

        var builder = SDKConfig.Builder()
            .enableLogging(true)
            .enableDebugMode(true)
            .defaultAdTimeout(10_000)
            .defaultAdPosition(.unknown)

        let authority = TestConfig.adRequestAuthority
        if !authority.isEmpty {
            builder = builder.adRequestAuthority(authority)
        }

        BidscubeSDK.initialize(config: builder.build())
        TestLog.append("Bidscube SDK initialized (v\(Constants.sdkVersion))")
        if !authority.isEmpty {
            TestLog.append("Ad authority: \(authority)")
        }
    }

    private func initializeAppLovinMAX() {
        guard TestConfig.isMaxConfigured else {
            TestLog.append("[MAX] Skipped — set APPLOVIN_SDK_KEY or AppLovinSdkKey in Info.plist")
            return
        }

        let initConfig = ALSdkInitializationConfiguration(sdkKey: TestConfig.appLovinSdkKey) { builder in
            builder.mediationProvider = ALMediationProviderMAX
        }
        ALSdk.shared().initialize(with: initConfig) { _ in
            TestLog.append("[MAX] AppLovin MAX initialized")
            if TestConfig.isMaxAdsConfigured {
                TestLog.append("[MAX] Ad units configured — open MAX tab to load ads")
            } else {
                TestLog.append("[MAX] Add MAX_*_AD_UNIT_ID for banner/interstitial/rewarded QA")
            }
            TestLog.append("[MAX] Custom adapter: ALBidscubeMediationAdapter (from BidscubeSDKAppLovin pod)")
        }
    }
}
