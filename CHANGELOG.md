# Changelog

All notable changes to the Bidscube iOS SDK and AppLovin MAX adapter are documented here.

## [Unreleased]

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

- `showImageAd`, `showVideoAd`, and `showNativeAd` present through `AdViewController` when no custom render override is used.
- `NetworkManager` treats HTTP 204 as no-fill; other HTTP errors map to stable `AdErrorCode` values.

---

## [1.0.4] - prior release

- Initial published CocoaPods layout (`BidscubeSDKAppLovin`), MAX adapter `ALBidscubeMediationAdapter`, IMA video support.
