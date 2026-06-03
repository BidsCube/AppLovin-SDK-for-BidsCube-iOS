# Bidscube + AppLovin MAX (iOS)

**SDK / adapter 1.0.5** · CocoaPod `BidscubeSDKAppLovin`

AppLovin MAX custom network adapter for the Bidscube iOS SDK. The adapter ships inside the same pod as the runtime — no separate SDK pod is required for mediation.

**Related docs:** [Main README](../README.md) · [Error codes](../docs/errors.md) · [CHANGELOG](../CHANGELOG.md) · [RELEASE](../RELEASE.md)

## Requirements

- **iOS** 13.0+
- **AppLovin MAX SDK** 13.x
- **Xcode** 15+, Swift 5.9+
- MAX **Adapter Class Name:** `ALBidscubeMediationAdapter`
- Bidscube **Placement ID** in MAX **App ID** (and optional `request_authority` / `ssp_host`)

## Installation

```ruby
source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

pod 'AppLovinSDK', '>= 13.0.0', '< 14.0'
pod 'BidscubeSDKAppLovin', '1.0.5'
```

## MAX integration notes

- The adapter calls `BidscubeSDK.setDisplayViewController(_:)` with MAX’s presenting view controller before show/load.
- Ad failures use stable codes from `AdErrorCode` (for example **204** for HTTP no-fill). See [docs/errors.md](../docs/errors.md).
- Interstitial uses image placement; rewarded uses video (IMA VAST by default).

## Supported formats

Banner, MREC, Leader, Interstitial, Rewarded, Native.
