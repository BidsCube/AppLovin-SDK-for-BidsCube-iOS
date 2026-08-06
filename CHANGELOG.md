# Changelog

All notable changes to the Bidscube iOS SDK and AppLovin MAX adapter are documented here.

## [1.1.4] - 2026-08-06

### Fixed

- CI sample-app build: removed duplicate local `BidscubeSDK` Xcode framework target that conflicted with the CocoaPods `BidscubeSDKAppLovin` pod (`module_name = BidscubeSDK`), which caused `ld: framework 'BidscubeSDK' not found` on GitHub Actions.
- `testApp-ios` scheme now builds pod dependencies (`BidscubeSDKAppLovin`) before linking; CI uses a single `xcodebuild` invocation with a shared derived data path.

---

## [1.1.3] - 2026-08-06

### Added

- **`BidscubeSDKAppLovinLegacy`** CocoaPod for **iOS 14+** with the same module name (`BidscubeSDK`) and MAX adapter (`ALBidscubeMediationAdapter`).
- AVPlayer-based legacy VAST video player (`LegacyVideoAdHandler`) with wrapper redirect resolution, MP4 playback, quartile/skip/close tracking, companion end cards, and `autoClose` parity.
- `VastResolver` and extended `VastParser.parseInlineAd` for legacy inline VAST support.
- `Podfile.legacy.example` and in-repo `BidscubeSDKAppLovinLegacy/{version}/` podspec layout.
- `legacyIntegration/` CocoaPods workspace with **LegacySmoke** (legacy SDK) and **BidscubeSDKAppLovinTestApp** (modern SDK) sample targets; CI build scripts and unit-test harness (`spmUnitTests/`).

### Changed

- Modern **`BidscubeSDKAppLovin`** remains **iOS 15+**; Google IMA dependency `~> 3.32.0` (`>= 3.32.0`, `< 3.33.0`); AppLovin SDK `~> 13.6.0`.
- Centralized ad session callback lifecycle (`AdSessionCoordinator`) prevents duplicate `onAdFailed` and late success callbacks after failure/close.
- Legacy VAST wrapper resolution pings accumulated Error URLs on failure; companion inheritance from inline/wrapper layers.
- `BannerAdMarkupNormalizer` strips `document.write(...)` and nested `{ "adm": "..." }` JSON envelopes from banner/image SSP responses (including malformed nested span HTML).
- `VideoAdView` accepts raw VAST XML responses and routes playback through `VideoAdView+Playback` (IMA for modern, legacy AVPlayer when `BIDSCUBE_LEGACY_VIDEO` is set).
- `NativeAdView` avoids zero-size layout mode selection before the view is laid out.

### Notes

- Install **only one** of `BidscubeSDKAppLovin` or `BidscubeSDKAppLovinLegacy` per target.
- Swift Package Manager supports **modern iOS 15+ only**; use CocoaPods for legacy iOS 14.
- In-repo test apps (`testApp*`, `legacyIntegration/`) are excluded from `git archive` source packages; integration workspaces generate `Pods/` locally.

---

## [1.1.2] - 2026-08-05

### Added

- **`SDKConfig.Builder.autoClose(_:)`** (default **`false`**): fullscreen video stays open after linear playback for VAST Companion, last frame, or manual close; `onAdClosed` fires only on user/system close. When **`true`**, ad dismisses immediately after linear video ends or is skipped.
- VAST Companion post-video support: `StaticResource`, `HTMLResource`, `IFrameResource`, click-through, and tracking (HTML > IFrame > Static priority).
- `VideoSkipControlOverlay` — skip countdown (`Skip in N` → `Skip`), default **15 s** or VAST `Linear@skipoffset`.
- `FullscreenVideoSessionController` state machine and centralized fullscreen dismiss in `IMAVideoAdHandler` / `AdViewController.dismissAdOnce()`.
- MAX adapter forwards init server parameters **`auto_close`** / **`autoClose`** to `SDKConfig.Builder.autoClose(...)`.

### Tests

- `FullscreenVideoSessionControllerTests`, `VastParserCompanionTests`.

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
