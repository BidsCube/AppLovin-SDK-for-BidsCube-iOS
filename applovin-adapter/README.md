# Bidscube + AppLovin MAX (iOS)

**SDK / adapter 1.1.3** · CocoaPods `BidscubeSDKAppLovin` or `BidscubeSDKAppLovinLegacy`

AppLovin MAX custom network adapter for the Bidscube iOS SDK. The adapter ships inside the same pod as the runtime — no separate SDK pod is required for mediation.

**Related docs:** [Main README](../README.md) · [Error codes](../docs/errors.md) · [CHANGELOG](../CHANGELOG.md) · [RELEASE](../RELEASE.md)

## Pod variants

| Pod | Minimum iOS | Video | Notes |
| --- | ---: | --- | --- |
| `BidscubeSDKAppLovin` | iOS 15+ | Google IMA | Recommended |
| `BidscubeSDKAppLovinLegacy` | iOS 14+ | AVPlayer VAST | No Google IMA |

> Install only one Bidscube AppLovin pod. Do not install the modern and legacy variants in the same target.

Both pods expose module `BidscubeSDK` and adapter `ALBidscubeMediationAdapter`. Publisher Swift integration code does not change when switching pods.

## Requirements

- **AppLovin MAX SDK** 13.x (pulled transitively)
- **Xcode** 15+, Swift 5.9+
- MAX **Adapter Class Name:** `ALBidscubeMediationAdapter`
- Bidscube **Placement ID** in MAX **App ID**

## Installation

### Modern (iOS 15+)

```ruby
platform :ios, '15.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovin', '1.1.3'
end
```

### Legacy (iOS 14+)

```ruby
platform :ios, '14.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovinLegacy', '1.1.3'
end
```

```bash
pod install --repo-update
```

Open the generated `.xcworkspace` in Xcode.

`BidscubeSDKAppLovin` pulls `GoogleAds-IMA-iOS-SDK` (`~> 3.32.0`, i.e. `>= 3.32.0` and `< 3.33.0`) and `AppLovinSDK` (`~> 13.6.0`). `BidscubeSDKAppLovinLegacy` does not include Google IMA.

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

- Interstitial and rewarded use the **video** Bidscube path (IMA VAST).
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

- **Native MAX** is not supported. Native ads require the direct SDK API.
- OpenRTB 2.6-style podded video response parsing is not implemented in this package.

## Sample app

For local testing, use the sibling app **`BidscubeSDKAppLovinTestApp`** (Banner / Video / Native tabs = direct SDK; MAX tab = mediation). See the test app README in your workspace checkout.
