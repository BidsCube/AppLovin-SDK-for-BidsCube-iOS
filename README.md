# Bidscube SDK for iOS (AppLovin MAX)

Single CocoaPod that bundles the Bidscube runtime and the AppLovin MAX custom SDK adapter.

Repository: [https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS](https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS)

## Requirements

- iOS 15.0+ (required by Google IMA SDK for video ads)
- Xcode 15+
- Swift 5.9+
- CocoaPods (recommended integration path)
- AppLovin MAX SDK 13.x (included transitively by `BidscubeSDKAppLovin`)

## Installation

Podspecs are hosted **in this GitHub repository** (CocoaPods spec-repo layout). **CocoaPods Trunk is not used.**

```ruby
platform :ios, '15.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovin', '1.2.0'
end
```

`BidscubeSDKAppLovin` pulls `AppLovinSDK` and `GoogleAds-IMA-iOS-SDK` transitively. You do not need a separate `pod 'AppLovinSDK'` unless you want to pin a specific MAX version.

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
| **Server parameters (optional)** | `app_id`, `request_authority`, `ssp_host`, `user_id` (or `userId`) — SSP host and publisher user id for postbacks |

If `request_authority` or `ssp_host` is set, the adapter uses it as the ad request authority.

If `user_id` (or `userId`) is set, the SDK includes it on every ad request as the `user_id` query parameter for server-side postback attribution.

Optional init server parameter **`auto_close`** (alias `autoClose`): when `true`, fullscreen video closes immediately after linear playback ends or is skipped. Default is **`false`** (keep ad open for VAST Companion, last frame, or manual close).

### Direct SDK initialization with user id

```swift
let config = SDKConfig.Builder()
    .adRequestAuthority("your-ssp-host.example.com")
    .userId("publisher-user-123")
    .build()

BidscubeSDK.initialize(config: config)
```

Fullscreen auto-close (default `false`):

```swift
BidscubeSDK.initialize(config: SDKConfig.Builder().autoClose(false).build())
```

Update after login without re-initializing:

```swift
BidscubeSDK.setUserId("publisher-user-456")
```

## Supported ad formats

- Banner
- MREC
- Interstitial (video)
- Rewarded

**Not supported:** Native MAX

Native MAX is not supported in this release. Native support requires real asset mapping from Bidscube native response to `MANativeAd`.

Use your usual MAX APIs (`MAAdView`, `MAInterstitialAd`, `MARewardedAd`, etc.).

## OpenRTB

OpenRTB 2.6-style podded video response parsing is not implemented in this package yet.
The adapter does not build or POST OpenRTB bid requests.

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

Interstitial and rewarded ads use the **video** Bidscube path with **Google IMA SDK** (`GoogleAds-IMA-iOS-SDK`) for VAST playback. This dependency is included automatically by `BidscubeSDKAppLovin`.

During MAX load, the adapter fetches and caches the Bidscube response. Show presents from the cached payload without a second network request.

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

## Error codes

Ad failures are reported through `AdCallback.onAdFailed(placementId, errorCode, errorMessage)` using stable codes in `AdErrorCode` (for example **204** for HTTP no-fill). See [docs/errors.md](docs/errors.md).

For MAX or apps that initialize early without a presenter, the adapter calls `BidscubeSDK.setDisplayViewController(_:)` before show/load so full-screen ads always have a host view controller.

## Troubleshooting

- **`Unable to find a specification for 'BidscubeSDKAppLovin'`:** add `source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'` above your pods (see [Installation](#installation)), then run `pod install --repo-update`.
- **Ads do not load:** confirm **App ID** contains the correct BidCube **Placement ID**.
- **HTTP 204 / no fill:** code `204` is expected when the SSP has no ad; it is not a crash.
- **SSP override:** use only host or `host:port` in `request_authority` / `ssp_host`.
- **Custom network not found:** class name must be exactly `ALBidscubeMediationAdapter`.

## Sample app (testing)

For local MAX integration testing, use the sibling test app **`BidscubeSDKAppLovinTestApp`** (next to this repository, not inside it):

```text
workspace/
  AppLovin-SDK-for-BidsCube-iOS/
  BidscubeSDKAppLovinTestApp/
```

See [`../BidscubeSDKAppLovinTestApp/README.md`](../BidscubeSDKAppLovinTestApp/README.md) for setup.

The in-repo [`testApp/`](testApp/) folder is a legacy internal SwiftUI sample. Do not use it for publisher-style MAX QA; prefer the sibling test app.

## Publisher integration checklist

Quick steps for app publishers integrating Bidscube via AppLovin MAX:

1. **Add the pod** — in your app `Podfile`:

   ```ruby
   platform :ios, '15.0'
   use_frameworks!

   source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
   source 'https://cdn.cocoapods.org/'

   target 'YourApp' do
     pod 'BidscubeSDKAppLovin', '1.2.0'
   end
   ```

   Then run `pod install --repo-update` and open the `.xcworkspace`.

2. **Configure MAX Dashboard** — [Integrating custom SDK networks](https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/):
   - **Networks → Add Custom Network** (type: SDK)
   - **iOS Adapter Class Name:** `ALBidscubeMediationAdapter`
   - Enable **Bidscube** on each MAX ad unit (banner, MREC, interstitial, rewarded).

3. **Set placement ID** — in each ad unit’s Bidscube settings, put your BidCube **Placement ID** in the **App ID** field (MAX label; required for this network).

4. **Optional SSP override** — server parameter `request_authority` or `ssp_host` (`host` or `host:port`).

5. **Initialize MAX** in your app (standard AppLovin flow). You do **not** need `BidscubeSDK.initialize(...)` for normal MAX mediation — the adapter loads the SDK when MAX requests ads.

6. **Load ads** with standard MAX APIs (`MAAdView`, `MAInterstitialAd`, `MARewardedAd`).

7. **Verify** — use MAX Mediation Debugger and confirm Bidscube appears on the waterfall for your ad units.

See also [`Podfile.example`](Podfile.example), [`docs/errors.md`](docs/errors.md), and [`RELEASE.md`](RELEASE.md) for publishing **1.2.0**.

## License

MIT. See [LICENSE](LICENSE).

## Version

BidscubeSDKAppLovin **1.2.0**
