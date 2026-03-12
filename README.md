# BidsCube Adapter for AppLovin MAX (iOS)

**BidscubeSDKAppLovin** is the official adapter to show BidCube ads (banner, interstitial, rewarded, MREC, native) through **AppLovin MAX** mediation. You integrate with AppLovin MAX only; no separate BidCube SDK or custom initialization in your app code.

**Repository:** [https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS](https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS)

---

## Requirements

- **iOS 14.0+**
- **Xcode 12+**
- **AppLovin MAX SDK** **13.0.0+**
- AppLovin **SDK Key** and **Ad Unit IDs**
- BidCube **Placement ID(s)** (from your BidCube account)

---

## Installation

### CocoaPods

In your app’s **Podfile**:

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  pod 'AppLovinSDK', '>= 13.0.0'
  pod 'BidscubeSDKAppLovin', '~> 1.0.1'
end
```

Then run:

```bash
pod install
```

Open the `.xcworkspace` and build. You do **not** add or initialize any separate BidCube SDK — the adapter is used by AppLovin MAX automatically once configured.

---

## AppLovin MAX setup

1. **Initialize AppLovin MAX** in your app as you normally do (e.g. with your AppLovin SDK Key).
2. In the **AppLovin MAX Dashboard** → your app → **Mediation** → **Manage Mediation**:
   - Add a **Custom network** named **Bidscube**.
   - Set the **server parameter**: **`app_id`** = your **BidCube Placement ID** (not the Application ID).
   - For **native** ad units, you can add a local parameter **`is_native`** = **`true`**.
   - Enable **Bidscube** for the ad units where you want BidCube demand.

3. Use your existing AppLovin MAX API to load and show ads (e.g. `MAInterstitialAd`, `MARewardedAd`, `MAAdView`). MAX will call this adapter when it needs BidCube demand; no extra code in your app for BidCube.

---

## Supported ad formats

- **Banner**
- **Interstitial**
- **Rewarded**
- **MREC**
- **Native**

---

## Summary

| Item | Value |
|------|--------|
| **Pod name** | `BidscubeSDKAppLovin` |
| **AppLovin** | `AppLovinSDK` ≥ 13.0.0 |
| **MAX custom network** | Bidscube |
| **Server parameter** | `app_id` = BidCube **Placement ID** |

There is no separate “BidscubeSDK” pod to install and no `BidscubeSDK.initialize(...)` in your app — only **BidscubeSDKAppLovin** and your usual AppLovin MAX setup.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
