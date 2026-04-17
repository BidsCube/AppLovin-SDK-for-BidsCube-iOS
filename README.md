# Bidscube SDK for iOS

iOS SDK and AppLovin MAX adapter for BidCube demand. For mediation, use the **BidscubeSDKAppLovin** CocoaPod: it bundles the BidCube runtime and the MAX adapter (`ALBidscubeMediationAdapter`).

Repository: [https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS](https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS)

## Requirements

- iOS 13.0+
- CocoaPods: `BidscubeSDKAppLovin` and `AppLovinSDK` 13.x
- Xcode 14+ recommended
- In MAX, put the BidCube **Placement ID** in the custom network **App ID** field (see below)

## AppLovin MAX — installing the adapter

### CocoaPods

Add a single Bidscube pod (runtime + adapter) and AppLovin MAX:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'AppLovinSDK', '>= 13.0.0', '< 14.0'
  pod 'BidscubeSDKAppLovin', '1.0.3.1'
end
```

Then:

```bash
pod install
```

Open the generated `.xcworkspace` in Xcode. Do not add a separate `BidscubeSDK` pod for the same target.

### MAX Dashboard

Follow AppLovin’s guide for custom SDK networks:  
[Integrating custom SDK networks](https://support.axon.ai/en/max/mediated-network-guides/integrating-custom-sdk-networks/)

1. Open your app in the AppLovin MAX Dashboard.
2. Go to **MAX → Mediation → Manage → Networks**.
3. **Add a Custom Network**:
   - Network Type: **SDK**
   - Name: **Bidscube** (or your label)
   - **iOS Adapter Class Name:** `ALBidscubeMediationAdapter`
4. Go to **MAX → Mediation → Manage → Ad Units**, open each ad unit that should use Bidscube, enable **Bidscube**, and set placement fields as below.

### MAX parameters

| Field | Value |
|--------|--------|
| **iOS Adapter Class Name** | `ALBidscubeMediationAdapter` |
| **App ID** | BidCube **Placement ID** (MAX still labels this “App ID”; for this network it must be the placement ID) |
| **Placement ID** | Optional; leave empty unless your MAX setup needs a second value |
| **Server parameters (optional)** | `request_authority` or `ssp_host` — SSP host or `host:port` (normalized the same way as a standalone `adRequestAuthority`) |

If `request_authority` or `ssp_host` is set, the adapter uses it as the ad request authority.

## Custom video player

Clients can choose the video player through SDK configuration.

By default, the SDK uses the built-in **IMA** player. To provide a custom player:

```swift
final class MyVideoPlayerView: UIView, BidscubeCustomVideoPlayer {
    func setPlacementInfo(_ placementId: String, callback: AdCallback?) {}
    func setParentViewController(_ viewController: UIViewController?) {}
    func loadVAST(source: String, isURL: Bool, clickURL: String?) {
        // Render your own player here
    }
    func cleanup() {}
}

final class MyVideoPlayerFactory: BidscubeCustomVideoPlayerFactory {
    func makeVideoPlayer() -> (UIView & BidscubeCustomVideoPlayer) {
        MyVideoPlayerView()
    }
}

BidscubeSDK.configureVideoPlayer(
    type: .custom,
    factory: MyVideoPlayerFactory()
)
```

Call this before AppLovin MAX initialization if you use the adapter path.

If `.custom` is selected without a factory, the SDK logs a warning and falls back to the default IMA player.

### Supported ad formats

Banner, MREC, Interstitial, Rewarded, Native.

### Troubleshooting

- Ads do not load: confirm **App ID** contains the correct BidCube **Placement ID**.
- SSP override: use only host or `host:port` in `request_authority` / `ssp_host`.
- Custom network not found: class name must be exactly `ALBidscubeMediationAdapter`.
- Native: if your setup uses a native-specific local parameter, set `is_native = true` where applicable.

## Runtime behavior

Use your usual MAX APIs (`MAInterstitialAd`, `MARewardedAd`, `MAAdView`, `MANativeAdLoader`, etc.). The adapter initializes the BidCube runtime internally; you do **not** need to call `BidscubeSDK.initialize(...)` in app code for MAX mediation.

## Sample app (testing)

The bundled sample app can point at a test SSP via environment variables:

- `bidcube.testSspAuthority`
- `BIDSCUBE_TEST_SSP_AUTHORITY`

## License

MIT. See [LICENSE](LICENSE).

## Version

AppLovin Bidscube iOS SDK 1.0.3.1.
