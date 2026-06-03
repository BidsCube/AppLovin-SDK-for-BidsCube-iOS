# Bidscube MAX Test App

Sample iOS app for testing **BidscubeSDKAppLovin** via AppLovin MAX.

Open **`bidscubeSdk.xcworkspace`**, select scheme **`testApp-ios`**, run on simulator or device (iOS 15+).

## Setup

1. Install pods from repo root:

```bash
pod install
```

2. Configure AppLovin in **Xcode → testApp-ios → Edit Scheme → Run → Arguments → Environment Variables**:

| Variable | Description |
|----------|-------------|
| `APPLOVIN_SDK_KEY` | AppLovin MAX SDK key |
| `MAX_BANNER_AD_UNIT_ID` | MAX ad unit with Bidscube banner |
| `MAX_MREC_AD_UNIT_ID` | MAX ad unit with Bidscube MREC |
| `MAX_INTERSTITIAL_AD_UNIT_ID` | MAX interstitial ad unit |
| `MAX_REWARDED_AD_UNIT_ID` | MAX rewarded ad unit |
| `MAX_NATIVE_AD_UNIT_ID` | MAX native ad unit |
| `BIDSCUBE_TEST_SSP_AUTHORITY` | Optional SSP host override |

Alternatively set `AppLovinSdkKey` and `MAX_*` keys in `testApp-Info.plist` at the repo root.

3. In MAX Dashboard, enable **Bidscube** on each ad unit and set **App ID** to your BidCube placement ID. Adapter class: `ALBidscubeMediationAdapter`.

## Source layout

```
testApp/
  TestAppApp.swift           App entry
  MAXTestView.swift          UI
  MAXAdCoordinator.swift     MAX ad loading / delegates
  MAXAdViews.swift           Banner / MREC / native containers
  TestAppConfiguration.swift
  Assets.xcassets
testApp-Info.plist           App Info.plist (AppLovin keys, SKAdNetwork)
```

The app pulls **`BidscubeSDKAppLovin` 1.0.5 from this GitHub repo** (same as publisher integration) — no CocoaPods Trunk required.

For local SDK development against uncommitted changes, temporarily use:

```ruby
pod 'BidscubeSDKAppLovin', :podspec => 'BidscubeSDKAppLovin.podspec'
```
