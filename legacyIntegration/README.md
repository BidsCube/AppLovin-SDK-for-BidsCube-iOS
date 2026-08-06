# Legacy + modern test apps (`BidscubeSDKAppLovinLegacy` / `BidscubeSDKAppLovin`)

Two app targets in one workspace for SDK QA on iOS Simulator.

## Quick start

### Legacy app (iOS 14+, AVPlayer VAST)

```bash
chmod +x scripts/run-legacy-test-app.sh
./scripts/run-legacy-test-app.sh
```

Scheme: **LegacySmoke** · pod: `BidscubeSDKAppLovinLegacy`

### Modern app (iOS 15+, Google IMA VAST)

```bash
chmod +x scripts/run-modern-test-app.sh
./scripts/run-modern-test-app.sh
```

Scheme: **BidscubeSDKAppLovinTestApp** · pod: `BidscubeSDKAppLovin`

Or open `legacyIntegration/LegacySmoke.xcworkspace` in Xcode and pick the scheme.

## Configuration

Set values in `LegacySmoke/Info.plist` or `ModernTestApp/Info.plist` **or** Xcode scheme environment variables:

| Key | Purpose |
|-----|---------|
| `AppLovinSdkKey` / `APPLOVIN_SDK_KEY` | AppLovin MAX SDK key |
| `BIDSCUBE_BANNER_PLACEMENT_ID` | Direct SDK banner (default `20212`) |
| `BIDSCUBE_VIDEO_PLACEMENT_ID` | Direct SDK video (default `20213`) |
| `BIDSCUBE_NATIVE_PLACEMENT_ID` | Direct SDK native (default `20214`) |
| `MAX_BANNER_AD_UNIT_ID` | Banner ad unit |
| `MAX_MREC_AD_UNIT_ID` | MREC ad unit |
| `MAX_INTERSTITIAL_AD_UNIT_ID` | Interstitial ad unit |
| `MAX_REWARDED_AD_UNIT_ID` | Rewarded ad unit |
| `BIDSCUBE_TEST_SSP_AUTHORITY` | Optional SSP override for staging |

## What you can test

**LegacySmoke** (SwiftUI)

1. **Direct SDK API** — `BidscubeSDK.initialize()`, inline banner, `showVideoAd`, `showNativeAd` (AVPlayer).
2. **AppLovin MAX** — banner, MREC, interstitial, rewarded.

**BidscubeSDKAppLovinTestApp** (UIKit tabs from sibling `../../BidscubeSDKAppLovinTestApp`)

1. **Banner / Video / Native** tabs — direct SDK with Google IMA for VAST.
2. **MAX** tab — mediation via `ALBidscubeMediationAdapter`.

Native MAX is not supported by the adapter in this release.

## CI

`scripts/build-legacy-integration.sh` compiles both targets without launching the simulator.
