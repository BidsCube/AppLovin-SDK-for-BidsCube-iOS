# Bidscube + AppLovin MAX (iOS)

**SDK / adapter 1.1.2** · CocoaPod `BidscubeSDKAppLovin`

AppLovin MAX custom network adapter for the Bidscube iOS SDK. The adapter ships inside the same pod as the runtime — no separate SDK pod is required for mediation.

**Related docs:** [Main README](../README.md) · [Error codes](../docs/errors.md) · [CHANGELOG](../CHANGELOG.md) · [RELEASE](../RELEASE.md)

## Requirements

- **iOS** 15.0+
- **AppLovin MAX SDK** 13.x (pulled transitively by `BidscubeSDKAppLovin`)
- **Xcode** 15+, Swift 5.9+
- MAX **Adapter Class Name:** `ALBidscubeMediationAdapter`
- Bidscube **Placement ID** in MAX **App ID** (and optional `request_authority` / `ssp_host`)

## Installation

```ruby
platform :ios, '15.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovin', '1.1.2'
end
```

`BidscubeSDKAppLovin` pulls `AppLovinSDK` and `GoogleAds-IMA-iOS-SDK` transitively.

## MAX integration notes

- The adapter calls `BidscubeSDK.setDisplayViewController(_:)` with MAX’s presenting view controller before show/load.
- Ad failures use stable codes from `AdErrorCode` (for example **204** for HTTP no-fill). See [docs/errors.md](../docs/errors.md).
- Optional server parameter `user_id` (or `userId`) is forwarded as `user_id` on SSP ad requests for postback attribution.
- Optional init server parameter **`auto_close`** (alias `autoClose`): `true` / `false`, default **`false`**. Passed to `SDKConfig.Builder.autoClose(...)`. When `false`, fullscreen video stays open after linear playback for VAST Companion or last frame; `onAdClosed` fires only on manual/system close.
- Interstitial and rewarded use the **video** Bidscube path (IMA VAST by default).
- Load caches the Bidscube response; show presents from the cached payload (no second network request).
- Signal collection returns structured JSON via `MASignalProvider` (no device identifiers or PII).

## Supported formats

- Banner
- MREC
- Leader
- Interstitial (video)
- Rewarded

**Not supported:** Native MAX. Native support requires real asset mapping from Bidscube native response to `MANativeAd`.

## OpenRTB

OpenRTB 2.6-style podded video response parsing is not implemented in this package yet.
The adapter does not build or POST OpenRTB bid requests.

## Limitations

Native MAX is not supported in this release. Native support requires real asset mapping from Bidscube native response to `MANativeAd`.
