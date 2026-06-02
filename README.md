# Bidscube SDK for iOS (AppLovin MAX)

Single CocoaPod that bundles the Bidscube runtime and the AppLovin MAX custom SDK adapter.

Repository: [https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS](https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS)

## Requirements

- iOS 13.0+
- Xcode 15+
- Swift 5.9+
- CocoaPods (recommended integration path)
- AppLovin MAX SDK 13.x

## Installation

Podspecs are hosted **in this GitHub repository** (CocoaPods spec-repo layout). **CocoaPods Trunk is not used.**

Add both sources, AppLovin MAX, and Bidscube to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'AppLovinSDK', '>= 13.0.0', '< 14.0'
  pod 'BidscubeSDKAppLovin', '1.0.4'
end
```

Then:

```bash
pod install --repo-update
```

Open the generated `.xcworkspace` in Xcode.

See also [`Podfile.example`](Podfile.example).

### Swift Package Manager

SPM support is experimental. AppLovin does not officially distribute MAX mediation adapters via SPM, so **CocoaPods is the recommended integration method** for `BidscubeSDKAppLovin`.

## AppLovin MAX Dashboard

Follow AppLovin’s guide for custom SDK networks:  
[Integrating custom SDK networks](https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/)

1. Open your app in the AppLovin MAX Dashboard.
2. Go to **MAX → Mediation → Manage → Networks**.
3. **Add a Custom Network**:
   - Network Type: **SDK**
   - Name: **Bidscube** (or your label)
   - **iOS Adapter Class Name:** `ALBidscubeMediationAdapter`
4. Go to **MAX → Mediation → Manage → Ad Units**, enable **Bidscube** on each ad unit, and configure placement fields below.

### MAX parameters

| Field | Value |
|--------|--------|
| **iOS Adapter Class Name** | `ALBidscubeMediationAdapter` |
| **App ID** | BidCube **Placement ID** (MAX labels this “App ID”; for this network it must be the placement ID) |
| **Placement ID** | Optional; leave empty unless your MAX setup needs a second value |
| **Server parameters (optional)** | `request_authority` or `ssp_host` — SSP host or `host:port` |

If `request_authority` or `ssp_host` is set, the adapter uses it as the ad request authority.

## Supported ad formats

- Banner
- MREC
- Interstitial
- Rewarded
- Native

Use your usual MAX APIs (`MAAdView`, `MAInterstitialAd`, `MARewardedAd`, `MANativeAdLoader`, etc.).

## Initialization

### AppLovin MAX

Initialize AppLovin MAX as usual in your app delegate or startup flow:

```swift
import AppLovinSDK

let initConfig = ALSdkInitializationConfiguration(sdkKey: "YOUR_SDK_KEY") { builder in
    builder.mediationProvider = ALMediationProviderMAX
}
ALSdk.shared().initialize(with: initConfig) { _ in
    // MAX ready
}
```

The Bidscube adapter initializes the Bidscube runtime internally when MAX loads the custom network. You do **not** need to call `BidscubeSDK.initialize(...)` for standard MAX mediation.

### Optional: direct SDK configuration

If you need a custom video player or SSP override before MAX starts loading ads, configure the SDK early:

```swift
import BidscubeSDK

BidscubeSDK.configureVideoPlayer(type: .ima) // default
// or provide a custom player factory — see below
```

Optional server-side SSP override is also passed via MAX server parameters (`request_authority` / `ssp_host`).

## Video behavior

By default, interstitial and rewarded video ads use the **Google IMA SDK** (`GoogleAds-IMA-iOS-SDK`) for VAST playback. This dependency is included automatically by `BidscubeSDKAppLovin`.

### Custom video player (optional)

```swift
final class MyVideoPlayerView: UIView, BidscubeCustomVideoPlayer {
    func setPlacementInfo(_ placementId: String, callback: AdCallback?) {}
    func setParentViewController(_ viewController: UIViewController?) {}
    func loadVAST(source: String, isURL: Bool, clickURL: String?) {
        // Render your own player here
    }
    func cleanup() {}
}

final class MyVideoPlayerFactory: BidscubeCustomVideoPlayerFactory {
    func makeVideoPlayer() -> (UIView & BidscubeCustomVideoPlayer) {
        MyVideoPlayerView()
    }
}

BidscubeSDK.configureVideoPlayer(type: .custom, factory: MyVideoPlayerFactory())
```

Call this before AppLovin MAX initialization if you use a custom player. If `.custom` is selected without a factory, the SDK logs a warning and falls back to IMA.

## Troubleshooting

- **`Unable to find a specification for 'BidscubeSDKAppLovin'`:** add `source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'` above your pods (see [Installation](#installation)), then run `pod install --repo-update`.
- **Ads do not load:** confirm **App ID** contains the correct BidCube **Placement ID**.
- **SSP override:** use only host or `host:port` in `request_authority` / `ssp_host`.
- **Custom network not found:** class name must be exactly `ALBidscubeMediationAdapter`.
- **Native:** if your setup uses a native-specific local parameter, set `is_native = true` where applicable.

## Sample app (testing)

The bundled sample app can point at a test SSP via environment variables:

- `bidcube.testSspAuthority`
- `BIDSCUBE_TEST_SSP_AUTHORITY`

## License

MIT. See [LICENSE](LICENSE).

## Version

BidscubeSDKAppLovin **1.0.4**
