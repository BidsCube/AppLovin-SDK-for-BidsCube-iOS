# Bidscube SDK for iOS

iOS SDK and AppLovin MAX adapter for BidCube demand. This repository is distributed for MAX mediation as **BidscubeSDKAppLovin** and includes the embedded BidCube runtime used by the adapter.

Repository: [https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS](https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS)

## Requirements

- iOS 14.0+
- BidscubeSDKAppLovin 1.0.1+
- AppLovin MAX SDK 13.0.0+
- Xcode 12+
- For MAX mediation: BidCube Placement ID in the MAX `App ID` field

## Add the SDK

### CocoaPods

Assuming your project already uses CocoaPods, add:

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  pod 'AppLovinSDK', '>= 13.0.0'
  pod 'BidscubeSDKAppLovin', '1.0.1'
end
```

Then run:

```bash
pod install
```

### Local pod development

From this repo:

```bash
pod install
open bidscubeSdk.xcworkspace
```

## AppLovin MAX integration

To use Bidscube as a Custom network in AppLovin MAX:

### 1. Add dependencies

```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  pod 'AppLovinSDK', '>= 13.0.0'
  pod 'BidscubeSDKAppLovin', '1.0.1'
end
```

The embedded BidCube runtime is included by the adapter pod. Do not add or initialize a separate `BidscubeSDK` pod in app code.

### 2. MAX Dashboard setup

Follow AppLovin's guide for custom SDK networks:
[Integrating custom SDK networks](https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/)

Open the AppLovin MAX Dashboard and select your app.

Go to `MAX > Mediation > Manage > Networks`.

Click **Add a Custom Network** and create the network:

- Network Type: `SDK`
- Name: `Bidscube`
- iOS Adapter Class Name: `ALBidscubeMediationAdapter`

Go to `MAX > Mediation > Manage > Ad Units`, select each ad unit where you want Bidscube, enable **Bidscube**, and set the values for that placement.

### 3. MAX parameters

- iOS Adapter Class Name: `ALBidscubeMediationAdapter`
- App ID: BidCube **Placement ID** used by the adapter for the MAX mediation request
- Placement ID: optional / leave empty unless your MAX setup explicitly requires a second value
- Custom Parameters: not used by the current adapter implementation

The adapter reads the BidCube value from the MAX **App ID** field. Even though MAX labels that field as `App ID`, for this integration it must contain the BidCube **Placement ID**.

### 4. Supported ad formats

Banner, MREC, Interstitial, Rewarded, Native.

### 5. Troubleshooting

- If the network initializes but ads do not load, verify the MAX **App ID** field contains the correct BidCube **Placement ID**.
- If MAX does not recognize the custom network, verify the iOS adapter class name is `ALBidscubeMediationAdapter`.
- For native ad units, set `is_native = true` if your MAX setup uses a native-specific local parameter.

## Runtime behavior

Initialize and load ads using your normal AppLovin MAX integration (`MAInterstitialAd`, `MARewardedAd`, `MAAdView`, `MANativeAdLoader`, and so on).

The adapter initializes the embedded BidCube runtime internally. No direct `BidscubeSDK.initialize(...)` call is required in app code.

## Local build

From the project root:

```bash
pod install
open bidscubeSdk.xcworkspace
```

Requires Xcode and CocoaPods.

## License

MIT. See [LICENSE](LICENSE).

## Version

AppLovin Bidscube iOS SDK 1.0.1.
