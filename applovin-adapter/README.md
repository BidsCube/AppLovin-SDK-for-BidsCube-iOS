# Bidscube + AppLovin MAX (iOS)

**Release 1.1.10** · CocoaPods `BidscubeSDKAppLovin` (iOS 15+) or `BidscubeSDKAppLovinLegacy` (iOS 14+)

AppLovin MAX custom network adapter for the Bidscube iOS SDK. The adapter ships inside the same pod as the runtime — no separate SDK pod is required for mediation.

**Related docs:** [Main README](../README.md) · [Error codes](../docs/errors.md) · [CHANGELOG](../CHANGELOG.md) · [RELEASE](../RELEASE.md)

## Pod variants

| Pod | Version | Minimum iOS | Video engine | Transitive deps |
| --- | ---: | ---: | --- | --- |
| `BidscubeSDKAppLovin` | **1.1.10** | 15.0 | Google IMA VAST | `AppLovinSDK`, `GoogleAds-IMA-iOS-SDK` |
| `BidscubeSDKAppLovinLegacy` | **1.1.10** | 14.0 | AVPlayer VAST | `AppLovinSDK` only |

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
  pod 'BidscubeSDKAppLovin', '1.1.10'
end
```

### Legacy (`BidscubeSDKAppLovinLegacy`, iOS 14+)

```ruby
platform :ios, '14.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovinLegacy', '1.1.10'
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
3. Configure Bidscube on each ad unit (see **MAX parameters** below — same model as [Android](https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-Android)).

| Field | Value |
|---|---|
| **iOS Adapter Class Name** | `ALBidscubeMediationAdapter` |
| **`app_id` (Server Parameters)** | Bidscube **application / init** identifier (optional on iOS; required on Android) |
| **Placement ID** | Bidscube **placement** id for that MAX ad unit (used in SSP `id` / `placementId`) |

> **Android parity:** ad requests use MAX **Placement ID**, not `app_id`. If you set `app_id` in server parameters (as on Android), it must **not** replace the per-ad-unit placement id.

**Optional server parameters** (network or ad unit level):

| Parameter | Description |
|---|---|
| `request_authority` / `ssp_host` | SSP host override (`host` or `host:port`) |
| `enable_logging` / `enableLogging` | `true` / `false` — Bidscube log output (default: MAX test mode). When `true`, all Bidscube diagnostics are duplicated under the **`BidscubeMAX`** console tag. |
| `enable_debug_mode` / `enableDebugMode` / `debug` | `true` / `false` — verbose diagnostics incl. device info and WebView navigation (default: MAX test mode) |
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
- For Bidscube request URLs and SSP responses, filter device logs by **`BidscubeMAX`** (set `enable_logging=true` in MAX server parameters if not using test mode). See [Publisher logging](#publisher-logging-bidscubemax) below.

### Publisher logging (`BidscubeMAX`)

All Bidscube MAX adapter and banner/image network diagnostics are written to a **single console tag** so publishers can filter Xcode / `log` output without reading the full SDK stream.

#### Enable logging

**AppLovin MAX (recommended)** — add to Bidscube custom network or ad unit **Server parameters**:

| Parameter | Value |
|-----------|--------|
| `enable_logging` | `true` |

Optional verbose device / WebView details:

| Parameter | Value |
|-----------|--------|
| `enable_debug_mode` | `true` |

When MAX **test mode** is on and these parameters are omitted, logging defaults to **on** (same as test ads).

**Direct Bidscube SDK** (no MAX):

```swift
let config = SDKConfig.Builder()
    .enableLogging(true)
    .enableDebugMode(false) // set true for device info + WebView navigation
    .build()
BidscubeSDK.initialize(config: config)
```

#### Console filter

In **Xcode → Debug area → Console**, filter by:

```
BidscubeMAX
```

On device via Terminal:

```bash
log stream --predicate 'eventMessage CONTAINS "BidscubeMAX"'
```

#### Expected log lines (banner / MREC / leader)

When Bidscube wins a MAX AdView auction:

```
[BidscubeMAX] load BANNER placementId=YOUR_PLACEMENT …
[BidscubeMAX] Loading image/banner view for placement YOUR_PLACEMENT
[BidscubeMAX] Built image ad URL: https://…
[BidscubeMAX] Sending GET request to: https://…
[BidscubeMAX] SSP round-trip: 1.234s (timeout limit 10s)
[BidscubeMAX] Response code: 200
[BidscubeMAX] adView loading placementId=YOUR_PLACEMENT
[BidscubeMAX] adView loaded placementId=YOUR_PLACEMENT
[BidscubeMAX] adView displayed placementId=YOUR_PLACEMENT
[BidscubeMAX] Rendering HTML markup for placement YOUR_PLACEMENT
```

On failure:

```
[BidscubeMAX] Ad request failed (image) placement=… code=… message=…
[BidscubeMAX] adView failed placementId=… code=… message=…
```

#### Interstitial / rewarded (video)

```
[BidscubeMAX] load INTERSTITIAL placementId=… 
```

(video path uses `Logger.videoAd` — filter `BidscubeMAX` for URL/network lines; video player lines use `🎥 VideoAd` prefix)

#### Disable logging in production

Omit `enable_logging` and ensure MAX test mode is off — Bidscube logs are **silent** unless explicitly enabled.

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
- **Banner, MREC, and leader** use **`BidscubeSDK.getImageAdView`** (same as [Android MAX adapter](https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-Android)); MAX controls slot size — not `getBannerAdView` / screen attach APIs.
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
