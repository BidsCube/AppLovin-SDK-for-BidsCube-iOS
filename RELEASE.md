# Release 1.1.3

## Summary

Dual CocoaPods distribution: **modern** (`BidscubeSDKAppLovin`, iOS 15+, Google IMA) and **legacy** (`BidscubeSDKAppLovinLegacy`, iOS 14+, AVPlayer VAST). Same module (`BidscubeSDK`) and MAX adapter (`ALBidscubeMediationAdapter`).

## Publish checklist

1. **Review diff** — SDK, adapter, both podspecs, docs, legacy video sources.
2. **Verify spec layout** — `./scripts/sync-cocoapods-spec.sh` and confirm:
   - `BidscubeSDKAppLovin/1.1.3/BidscubeSDKAppLovin.podspec`
   - `BidscubeSDKAppLovinLegacy/1.1.3/BidscubeSDKAppLovinLegacy.podspec`
3. **Lint** — `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings` and `pod lib lint BidscubeSDKAppLovinLegacy.podspec --allow-warnings`
4. **Commit** on `main`, including both `1.1.3` spec folders.
5. **Tag and push** — `git tag v1.1.3 && git push origin main && git push origin v1.1.3`
6. **CI** — GitHub Actions `Publish SDK` runs on tag push.

### Pre-release local test

Modern:

```ruby
pod 'BidscubeSDKAppLovin', :path => '/path/to/AppLovin-SDK-for-BidsCube-iOS'
```

Legacy:

```ruby
pod 'BidscubeSDKAppLovinLegacy', :path => '/path/to/AppLovin-SDK-for-BidsCube-iOS'
```

## Integrator upgrade

Modern (recommended):

```ruby
platform :ios, '15.0'
pod 'BidscubeSDKAppLovin', '1.1.3'
```

Legacy (iOS 14+):

```ruby
platform :ios, '14.0'
pod 'BidscubeSDKAppLovinLegacy', '1.1.3'
```

> Install only one Bidscube AppLovin pod per target.

## Legacy limitations

- No Google IMA; VPAID and advanced IMA-only features are not supported.
- `BidscubeSDK.getIMAVideoAdView` is not available in the legacy pod (use `getAdViewControllerView` or UIKit `VideoAdView`).
- MP4 progressive media and supported VAST inline/wrapper flows only.

## Related

- [CHANGELOG.md](CHANGELOG.md)
- [README.md](README.md)
