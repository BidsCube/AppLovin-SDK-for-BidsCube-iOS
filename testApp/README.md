# Legacy internal MAX sample (SwiftUI)

This folder is a **legacy internal sample** bundled with the SDK repository. For publisher-style MAX integration testing, use the sibling test app instead:

```text
workspace/
  AppLovin-SDK-for-BidsCube-iOS/
  BidscubeSDKAppLovinTestApp/
```

See [`../BidscubeSDKAppLovinTestApp/README.md`](../BidscubeSDKAppLovinTestApp/README.md) (sibling repository folder).

## Legacy setup (optional)

Open **`bidscubeSdk.xcworkspace`**, select scheme **`testApp-ios`**, run on simulator or device.

This workspace uses the **modern** pod (`BidscubeSDKAppLovin`, iOS 15+). For legacy iOS 14 testing, create a separate app target with `Podfile.legacy.example`.

1. Install pods from repo root: `pod install`
2. Set `APPLOVIN_SDK_KEY` and `MAX_*_AD_UNIT_ID` via scheme environment variables.

Native MAX is not supported by the adapter in this release; do not configure `MAX_NATIVE_AD_UNIT_ID`.
