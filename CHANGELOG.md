# Changelog

All notable changes to the Bidscube iOS SDK and AppLovin MAX adapter are documented here.

## [Unreleased]

---

## [1.1.1] - 2026-07-24

### Added

- Publisher `user_id` support: `SDKConfig.Builder.userId(_:)`, `BidscubeSDK.setUserId(_:)`, and `BidscubeSDK.getUserId()`.
- SSP ad requests include `user_id` query parameter when set (banner, video, native).
- MAX adapter forwards server parameters `user_id` / `userId` to the SDK for postback attribution.

---

## [1.1.0] - 2026-07-08

### Added

- `BidscubeSDK.BidscubeAdPayload`, `loadAdPayload`, and `presentCachedAd` for true MAX load/show caching (no second network request at show).
- `BidscubeSDK.collectSignal()` and `MASignalProvider` on `ALBidscubeMediationAdapter` (structured JSON, no PII).
- Sibling MAX test app layout: `BidscubeSDKAppLovinTestApp` (outside this repository).
- `.gitattributes` export-ignore for legacy in-repo `testApp*` samples in release archives.

### Changed

- Interstitial MAX adapter uses video interstitial path (`AdType.video` + cached VAST presentation).
- Rewarded flow uses cached video payload at show time.
- Reward callback fires at most once after video completion (or `shouldAlwaysRewardUser`).
- MAX testing mode (`parameters.isTesting`) enables SDK debug logging during QA.
- Documentation and podspec: Native MAX explicitly unsupported; OpenRTB bid requests not implemented.

### Removed

- Native MAX adapter path (`MANativeAdAdapter`, `MABidscubeNativeAd`, native load/show helpers).

### Fixed

- MAX delegate and UI callbacks dispatched on the main thread via `runOnMain`.
- Documentation no longer claims Native MAX or OpenRTB bid request support.

---

## [1.0.5] - 2026-06-03

### Added

- Structured ad error codes in `AdErrorCode` (204, 1001–1006, -1), delivered via `AdCallback.onAdFailed`.
- `BidscubeRequestError`, `AdHTTPClient`, and `AdFailureDispatcher` for centralized HTTP / parse / network failures.
- `BidscubeSDK.setDisplayViewController(_:)` for MAX and custom integrations that need a bound host view controller.
- [docs/errors.md](docs/errors.md) — error code reference for integrators and support.

### Fixed

- HTTP **204 No Content** mapped to `AdErrorCode.noFill` (204) with a clear English message instead of a generic HTTP error.
- Unhandled ad request failures on background URL session threads no longer leave integrators without a callback; errors are reported through `onAdFailed` on the main thread.
- AppLovin MAX adapter binds the show `UIViewController` via `setDisplayViewController` before interstitial, rewarded, banner, and native calls.
- Removed premature `onAdLoaded` / `onAdDisplayed` callbacks fired before the creative actually loaded.

### Changed

- **Minimum iOS deployment target raised to 15.0** (Google IMA SDK requirement for rewarded / video ads).
- `showImageAd`, `showVideoAd`, and `showNativeAd` present through `AdViewController` when no custom render override is used.
- `NetworkManager` treats HTTP 204 as no-fill; other HTTP errors map to stable `AdErrorCode` values.

---

## [1.0.4] - prior release

- Initial published CocoaPods layout (`BidscubeSDKAppLovin`), MAX adapter `ALBidscubeMediationAdapter`, IMA video support.
