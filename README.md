# Bidscube SDK for iOS (AppLovin MAX)

Single CocoaPod that bundles the Bidscube runtime and the AppLovin MAX custom SDK adapter.

Repository: [https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS](https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS)

## Requirements

| Pod | Minimum iOS | Video implementation | For |
| --- | ---: | --- | --- |
| `BidscubeSDKAppLovin` | iOS 15+ | Modern Google IMA | **Recommended** default |
| `BidscubeSDKAppLovinLegacy` | iOS 14+ | Legacy AVPlayer VAST | Apps that must support iOS 14 |

> **Warning:** Install only one Bidscube AppLovin pod. Do not install the modern and legacy variants in the same target.

- Xcode 15+
- Swift 5.9+
- CocoaPods (recommended integration path)
- AppLovin MAX SDK 13.x (included transitively)

## Installation

Podspecs are hosted **in this GitHub repository** (CocoaPods spec-repo layout). **CocoaPods Trunk is not used.**

### Modern (recommended, iOS 15+)

```ruby
platform :ios, '15.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovin', '1.1.6'
end
```

See [`Podfile.example`](Podfile.example).

`BidscubeSDKAppLovin` pulls `AppLovinSDK` (`~> 13.2`, i.e. `>= 13.2.0` and `< 14.0`) and `GoogleAds-IMA-iOS-SDK` (`~> 3.32.0`, i.e. `>= 3.32.0` and `< 3.33.0`) transitively.

> **AppLovin pin:** You do **not** need `pod 'AppLovinSDK', ...` in your Podfile — Bidscube pulls it automatically. If you already pin AppLovin, use **13.2.0+**. On **iOS 14** use **13.2.x**; on **iOS 15+** you may use **13.6.x**.

### Legacy (iOS 14+)

```ruby
platform :ios, '14.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovinLegacy', '1.1.6'
end
```

See [`Podfile.legacy.example`](Podfile.legacy.example).

`BidscubeSDKAppLovinLegacy` uses the same module (`BidscubeSDK`) and MAX adapter (`ALBidscubeMediationAdapter`) with an AVPlayer-based VAST player. It does **not** depend on Google IMA.

```bash
pod install --repo-update
```

Open the generated `.xcworkspace` in Xcode.

### Swift Package Manager

SPM support is experimental and **modern iOS 15+ only**. For legacy iOS 14+, use CocoaPods (`BidscubeSDKAppLovinLegacy`). AppLovin does not officially distribute MAX mediation adapters via SPM, so **CocoaPods is the recommended integration method**.

CocoaPods uses pessimistic version constraints (`~>`), while `Package.swift` pins **exact** dependency versions:

| Dependency | CocoaPods (`BidscubeSDKAppLovin`) | Swift Package Manager |
| --- | --- | --- |
| Google IMA | `~> 3.32.0` (`>= 3.32.0`, `< 3.33.0`) | `3.32.0` (exact) |
| AppLovin MAX | `~> 13.2` (`>= 13.2.0`, `< 14.0`) | `13.2.0+` (`from:`) |

---

## Choose your integration path

| Path | When to use | `BidscubeSDK.initialize` required? |
|---|---|---|
| **[A — AppLovin MAX](#integration-a--applovin-max)** | Mediation waterfall, standard MAX ad units | **No** (adapter initializes SDK) |
| **[B — Direct SDK](#integration-b--direct-bidscube-sdk)** | Direct API calls, native ads, custom UI | **Yes** |
| **Both** | MAX for some formats, direct SDK for others | Optional early init for direct path |

Adapter-specific notes: [`applovin-adapter/README.md`](applovin-adapter/README.md)

---

## Integration A — AppLovin MAX

### 1. MAX Dashboard

Follow [Integrating custom SDK networks](https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/):

1. **MAX → Mediation → Manage → Networks → Add Custom Network**
   - Network Type: **SDK**
   - Name: **Bidscube**
   - **iOS Adapter Class Name:** `ALBidscubeMediationAdapter`
2. **MAX → Ad Units** — enable **Bidscube** on each ad unit.
3. Set **App ID** = your **Bidscube Placement ID**.

| Field | Value |
|---|---|
| **iOS Adapter Class Name** | `ALBidscubeMediationAdapter` |
| **App ID** | Bidscube **Placement ID** |
| **Placement ID** | Optional |

**Optional server parameters:** `request_authority`, `ssp_host`, `user_id` / `userId`, `auto_close` / `autoClose` (default `false`).

### 2. Initialize MAX

```swift
import AppLovinSDK

let initConfig = ALSdkInitializationConfiguration(sdkKey: "YOUR_SDK_KEY") { builder in
    builder.mediationProvider = ALMediationProviderMAX
}
ALSdk.shared().initialize(with: initConfig) { _ in
    // MAX ready
}
```

You do **not** need `BidscubeSDK.initialize(...)` for standard MAX mediation. The adapter initializes the Bidscube runtime when MAX loads the custom network.

### 3. Load ads with MAX APIs

```swift
import AppLovinSDK

// Banner
let bannerView = MAAdView(adUnitIdentifier: "YOUR_BANNER_AD_UNIT_ID")
bannerView.delegate = self
view.addSubview(bannerView)
bannerView.loadAd()

// MREC
let mrecView = MAAdView(adUnitIdentifier: "YOUR_MREC_AD_UNIT_ID", adFormat: .mrec)
mrecView.delegate = self
mrecView.loadAd()

// Interstitial
let interstitial = MAInterstitialAd(adUnitIdentifier: "YOUR_INTERSTITIAL_AD_UNIT_ID")
interstitial.delegate = self
interstitial.load()
// interstitial.show() when delegate reports ready

// Rewarded
let rewarded = MARewardedAd.shared(withAdUnitIdentifier: "YOUR_REWARDED_AD_UNIT_ID")
rewarded.delegate = self
rewarded.load()
// rewarded.show() when delegate reports ready
```

### 4. Verify

- Use **Mediation Debugger** (`ALSdk.shared().showMediationDebugger()`).
- Confirm Bidscube appears in the waterfall.
- When Bidscube wins: `network=Bidscube` in MAX logs.

### Supported MAX formats

- Banner, MREC, Leader
- Interstitial (video)
- Rewarded (video)

**Not supported:** Native MAX. Use [direct SDK](#integration-b--direct-bidscube-sdk) for native ads.

---

## Integration B — Direct Bidscube SDK

Use this when calling Bidscube APIs directly without MAX mediation.

### 1. Initialize SDK

Call **once** at app startup, before the first ad request:

```swift
import BidscubeSDK

let config = SDKConfig.Builder()
    .adRequestAuthority("ssp.example.com")   // optional SSP host override
    .userId("publisher-user-123")            // optional, for postbacks
    .autoClose(false)                        // default: keep fullscreen open after video
    .enableLogging(true)                     // optional, for debugging
    .build()

BidscubeSDK.initialize(config: config)
```

Update user id after login without re-initializing:

```swift
BidscubeSDK.setUserId("new-user-id")
```

### 2. Implement `AdCallback`

```swift
import BidscubeSDK

final class MyAdDelegate: NSObject, AdCallback {
    func onAdLoading(_ placementId: String) { }
    func onAdLoaded(_ placementId: String) { }
    func onAdDisplayed(_ placementId: String) { }
    func onAdClicked(_ placementId: String) { }
    func onAdClosed(_ placementId: String) { }
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        // e.g. 204 = no fill (not a crash)
    }

    // Optional for video:
    func onVideoAdStarted(_ placementId: String) { }
    func onVideoAdCompleted(_ placementId: String) { }
}
```

### 3. Set presenter for fullscreen ads

Before showing fullscreen video or native ads, bind the hosting view controller:

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    BidscubeSDK.setDisplayViewController(self)
}
```

Or pass the presenter explicitly in `showVideoAd(from:placementId:callback:)` / `showNativeAd(from:...)`.

### 4. Load and show ads

#### Banner (inline)

```swift
let delegate = MyAdDelegate()
let banner = BidscubeSDK.getBannerAdView("YOUR_PLACEMENT_ID", position: .footer, callback: delegate)
banner.setBannerDimensions(width: 320, height: 50)

// Add to your layout with explicit width/height constraints (320×50)
containerView.addSubview(banner)
```

Convenience methods (banner attaches to screen automatically):

```swift
BidscubeSDK.showFooterBanner("YOUR_PLACEMENT_ID", in: self, callback: delegate)
```

#### Video (inline preview)

```swift
let videoView = BidscubeSDK.getVideoAdView("YOUR_PLACEMENT_ID", delegate)
if let video = videoView as? VideoAdView {
    video.setParentViewController(self)
}
// Pin video view to container edges in your layout
containerView.addSubview(videoView)
```

#### Video (fullscreen)

```swift
BidscubeSDK.showVideoAd(from: self, placementId: "YOUR_PLACEMENT_ID", callback: delegate)
```

#### Native (inline)

```swift
let nativeView = BidscubeSDK.getNativeAdView("YOUR_PLACEMENT_ID", width: 320, height: 250, delegate)
// Add with 320×250 constraints
containerView.addSubview(nativeView)
```

#### Native (fullscreen)

```swift
BidscubeSDK.showNativeAd(
    from: self,
    placementId: "YOUR_PLACEMENT_ID",
    width: 320,
    height: 480,
    callback: delegate
)
```

### Direct SDK format summary

| Format | Inline API | Fullscreen API |
|---|---|---|
| Banner | `getBannerAdView` / `showFooterBanner` | — |
| Video | `getVideoAdView` | `showVideoAd` |
| Native | `getNativeAdView` | `showNativeAd` |
| Image | `getImageAdView` | `showImageAd` |

### MAX + Direct SDK in the same app

- You may call `BidscubeSDK.initialize(...)` early for direct ads; the MAX adapter will not re-initialize if the SDK is already initialized.
- If you only use MAX, skip manual `BidscubeSDK.initialize`.
- SSP override for MAX can be passed via dashboard server parameters (`request_authority` / `ssp_host`) instead of `SDKConfig`.

---

## Video behavior

Video playback depends on which pod you install:

| Pod | Video engine | Used for |
| --- | --- | --- |
| `BidscubeSDKAppLovin` | Google IMA (`GoogleAds-IMA-iOS-SDK`) | MAX interstitial/rewarded, direct `getVideoAdView` / `showVideoAd` |
| `BidscubeSDKAppLovinLegacy` | AVPlayer VAST (`LegacyVideoAdHandler`) | Same public APIs; **no Google IMA** |

During MAX load, the adapter fetches and caches the Bidscube response. Show presents from the cached payload without a second network request.

Fullscreen video layout fills the screen edge-to-edge. Video may letterbox to preserve aspect ratio.

### Modern only (`BidscubeSDKAppLovin`)

```swift
BidscubeSDK.configureVideoPlayer(type: .ima) // default
// or .custom with BidscubeCustomVideoPlayerFactory — see bidscubeSdk docs
```

Call before MAX initialization if you use a custom IMA-based player.

### Legacy only (`BidscubeSDKAppLovinLegacy`)

- MP4 progressive media and supported VAST inline/wrapper flows (no VPAID, no Google IMA).
- `BidscubeSDK.getIMAVideoAdView` is **not** available; use `getVideoAdView` or `showVideoAd`.
- `BidscubeSDK.configureVideoPlayer` IMA options do not apply.

---

## Error codes

Ad failures are reported through `AdCallback.onAdFailed(placementId, errorCode, errorMessage)` using stable codes in `AdErrorCode` (for example **204** for HTTP no-fill). See [docs/errors.md](docs/errors.md).

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `CocoaPods could not find compatible versions for pod "AppLovinSDK"` | Upgrade Bidscube to **`1.1.6+`**, or remove your explicit `AppLovinSDK` pin and let Bidscube resolve it. On **iOS 14** use AppLovin **13.2.x**; **13.6.x** may require iOS 15+ |
| `Unable to find a specification for 'BidscubeSDKAppLovin'` | Add `source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'` to Podfile, run `pod install --repo-update` |
| `Unable to find a specification for 'BidscubeSDKAppLovinLegacy'` | Legacy pod exists from **1.1.3** onward; use **`1.1.5`** (recommended), add the Git `source` above, run `pod install --repo-update` |
| Installing both pods in one target | Use **only one** pod per target — `BidscubeSDKAppLovin` (iOS 15+) **or** `BidscubeSDKAppLovinLegacy` (iOS 14+) |
| MAX ads do not load | Confirm **App ID** = correct Bidscube **Placement ID**; check Mediation Debugger |
| Direct ads not visible | Ensure ad views have explicit width/height Auto Layout constraints |
| `Empty ad unit ID` crash (MAX) | Do not create `MAInterstitialAd` / `MARewardedAd` with empty ad unit IDs |
| HTTP 204 / no fill | Code `204` is expected when SSP has no ad; not a crash |
| Custom network not found | Class name must be exactly `ALBidscubeMediationAdapter` |

---

## Sample app (testing)

Use the sibling test app **`BidscubeSDKAppLovinTestApp`** (next to this repository):

```text
workspace/
  AppLovin-SDK-for-BidsCube-iOS/     # SDK + adapter (this repo)
  BidscubeSDKAppLovinTestApp/         # UIKit test harness
```

| Tab | Tests |
|---|---|
| Banner / Video / Native | Direct SDK API |
| MAX | `MAAdView` / `MAInterstitialAd` / `MARewardedAd` via adapter |

The in-repo `testApp*` and `legacyIntegration/` folders are **gitignored** (local QA only). Use the sibling test app for publisher QA.

---

## Publisher quick checklist

### AppLovin MAX

1. Add pod `BidscubeSDKAppLovin` **`1.1.5`** (iOS 15+) or `BidscubeSDKAppLovinLegacy` **`1.1.5`** (iOS 14+) → `pod install --repo-update`
2. Dashboard: custom network `ALBidscubeMediationAdapter`, enable on ad units, **App ID** = placement ID
3. Initialize MAX with your SDK key
4. Load ads with `MAAdView` / `MAInterstitialAd` / `MARewardedAd`
5. Verify with Mediation Debugger

### Direct SDK

1. Add pod `BidscubeSDKAppLovin` **`1.1.5`** (iOS 15+) or `BidscubeSDKAppLovinLegacy` **`1.1.5`** (iOS 14+) → `pod install --repo-update`
2. Call `BidscubeSDK.initialize(config:)` at startup
3. Implement `AdCallback`
4. Call `setDisplayViewController` before fullscreen show
5. Use `getBannerAdView` / `getVideoAdView` / `showVideoAd` / `getNativeAdView` / `showNativeAd`

See also [`applovin-adapter/README.md`](applovin-adapter/README.md), [`docs/errors.md`](docs/errors.md), and [`RELEASE.md`](RELEASE.md).

## License

MIT. See [LICENSE](LICENSE).

## Version

Current release: **1.1.6** for both pods.

| Pod | Version | Minimum iOS |
| --- | ---: | ---: |
| `BidscubeSDKAppLovin` | **1.1.5** | 15.0 |
| `BidscubeSDKAppLovinLegacy` | **1.1.5** | 14.0 |

`BidscubeSDKAppLovinLegacy` was introduced in **1.1.3**; use **1.1.5** for the latest docs and repo layout.
