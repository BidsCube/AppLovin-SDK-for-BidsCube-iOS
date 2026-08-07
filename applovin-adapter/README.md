# Bidscube + AppLovin MAX (iOS)

**Release 1.1.5** · CocoaPods `BidscubeSDKAppLovin` (iOS 15+) or `BidscubeSDKAppLovinLegacy` (iOS 14+)

AppLovin MAX custom network adapter for the Bidscube iOS SDK. The adapter ships inside the same pod as the runtime — no separate SDK pod is required for mediation.

**Related docs:** [Main README](../README.md) · [Error codes](../docs/errors.md) · [CHANGELOG](../CHANGELOG.md) · [RELEASE](../RELEASE.md)

## Pod variants

| Pod | Version | Minimum iOS | Video engine | Transitive deps |
| --- | ---: | ---: | --- | --- |
| `BidscubeSDKAppLovin` | **1.1.6** | 15.0 | Google IMA VAST | `AppLovinSDK`, `GoogleAds-IMA-iOS-SDK` |
| `BidscubeSDKAppLovinLegacy` | **1.1.6** | 14.0 | AVPlayer VAST | `AppLovinSDK` only |

> Install only one Bidscube AppLovin pod per target. Do not install the modern and legacy variants in the same target.

Both pods expose:

- Swift module: **`BidscubeSDK`**
- MAX adapter: **`ALBidscubeMediationAdapter`**

Publisher Swift integration code (direct SDK API and MAX dashboard setup) does not change when switching pods. Only the video playback engine and minimum iOS version differ.

## Requirements

- **AppLovin MAX SDK** 13.x (pulled transitively as `~> 13.2`, i.e. `>= 13.2.0` and `< 14.0`)
- **Xcode** 15+, Swift 5.9+
- MAX **Adapter Class Name:** `ALBidscubeMediationAdapter`
- Bidscube **Placement ID** in MAX **App ID**

## Installation

### Modern (`BidscubeSDKAppLovin`, iOS 15+)

```ruby
platform :ios, '15.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovin', '1.1.6'
end
```

### Legacy (`BidscubeSDKAppLovinLegacy`, iOS 14+)

```ruby
platform :ios, '14.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovinLegacy', '1.1.6'
end
```

```bash
pod install --repo-update
```

Open the generated `.xcworkspace` in Xcode.

See also [`Podfile.example`](../Podfile.example) (modern) and [`Podfile.legacy.example`](../Podfile.legacy.example) (legacy).

---

## Integration A — AppLovin MAX (recommended for mediation)

Use this path when ads are loaded through MAX waterfall (`MAAdView`, `MAInterstitialAd`, `MARewardedAd`).

### 1. MAX Dashboard

Follow [Integrating custom SDK networks](https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/):

1. **MAX → Mediation → Manage → Networks → Add Custom Network**
   - Type: **SDK**
   - Name: **Bidscube**
   - **iOS Adapter Class Name:** `ALBidscubeMediationAdapter`
2. **MAX → Ad Units** — enable **Bidscube** on each ad unit (banner, MREC, interstitial, rewarded).
3. Set **App ID** = your **Bidscube Placement ID** (MAX label; required for this network).

| Field | Value |
|---|---|
| **iOS Adapter Class Name** | `ALBidscubeMediationAdapter` |
| **App ID** | Bidscube **Placement ID** |
| **Placement ID** | Optional; leave empty unless your MAX setup needs a second value |

**Optional server parameters** (network or ad unit level):

| Parameter | Description |
|---|---|
| `request_authority` / `ssp_host` | SSP host override (`host` or `host:port`) |
| `user_id` / `userId` | Publisher user id for postback attribution |
| `auto_close` / `autoClose` | `true` / `false`, default `false` — close fullscreen video immediately after linear playback |

### 2. Initialize AppLovin MAX

You do **not** need `BidscubeSDK.initialize(...)` for standard MAX mediation — the adapter initializes the Bidscube runtime when MAX loads the custom network.

```swift
import AppLovinSDK

let initConfig = ALSdkInitializationConfiguration(sdkKey: "YOUR_SDK_KEY") { builder in
    builder.mediationProvider = ALMediationProviderMAX
}
ALSdk.shared().initialize(with: initConfig) { _ in
    // MAX ready — load ads with standard MAX APIs
}
```

### 3. Load and show ads

Use your usual MAX APIs. The adapter handles Bidscube load/show internally.

```swift
import AppLovinSDK

// Banner / MREC
let bannerView = MAAdView(adUnitIdentifier: "YOUR_BANNER_AD_UNIT_ID")
bannerView.delegate = self
bannerView.loadAd()

// Interstitial
let interstitial = MAInterstitialAd(adUnitIdentifier: "YOUR_INTERSTITIAL_AD_UNIT_ID")
interstitial.delegate = self
interstitial.load()
// interstitial.show() when ready

// Rewarded
let rewarded = MARewardedAd.shared(withAdUnitIdentifier: "YOUR_REWARDED_AD_UNIT_ID")
rewarded.delegate = self
rewarded.load()
// rewarded.show() when ready
```

### 4. Verify

- Open **Mediation Debugger** from the AppLovin SDK.
- Confirm **Bidscube** appears in the waterfall for your ad units.
- When Bidscube wins, logs show `network=Bidscube`.

### Supported MAX formats

| Format | Supported |
|---|---|
| Banner | yes |
| MREC / Leader | yes |
| Interstitial (video) | yes |
| Rewarded (video) | yes |
| Native | **no** — use direct SDK API (see [Main README](../README.md#integration-b--direct-bidscube-sdk)) |

### MAX adapter behavior

- Interstitial and rewarded use the **video** Bidscube path:
  - **`BidscubeSDKAppLovin`** — Google IMA VAST playback
  - **`BidscubeSDKAppLovinLegacy`** — AVPlayer VAST playback (no Google IMA)
- Load caches the Bidscube response; show presents from cache (no second network request).
- `BidscubeSDK.setDisplayViewController(_:)` is called with MAX’s presenter before show/load.
- Signal collection via `MASignalProvider` (no device identifiers or PII).
- Ad failures use stable codes from `AdErrorCode` (e.g. **204** = no fill). See [docs/errors.md](../docs/errors.md).

---

## Integration B — Direct Bidscube SDK

Use this path when you call Bidscube APIs directly (`getBannerAdView`, `showVideoAd`, `getNativeAdView`, etc.) without MAX mediation.

See the full guide in the [Main README — Direct SDK integration](../README.md#integration-b--direct-bidscube-sdk).

You can use **both** paths in the same app: initialize Bidscube early for direct ads, and use MAX for mediated ads.

---

## Limitations

### Both pods

- **Native MAX** is not supported. Native ads require the direct SDK API.
- OpenRTB 2.6-style podded video response parsing is not implemented in this package.

### Legacy pod only (`BidscubeSDKAppLovinLegacy`)

- No Google IMA; VPAID and IMA-only features are not supported.
- `BidscubeSDK.getIMAVideoAdView` is not available.
- `BidscubeSDK.configureVideoPlayer` IMA options do not apply.
- MP4 progressive media and supported VAST inline/wrapper flows only.

## Sample apps

| App | Pod | Notes |
| --- | --- | --- |
| Sibling `BidscubeSDKAppLovinTestApp` | `BidscubeSDKAppLovin` / `BidscubeSDKAppLovinLegacy` | Recommended publisher QA (outside this repo) |
| Local `:path` pod in your app | either pod | Smoke-test before integrating |

In-repo `testApp*` / `legacyIntegration/` projects are gitignored and kept for local development only.

Native MAX is not supported by the adapter in this release.
