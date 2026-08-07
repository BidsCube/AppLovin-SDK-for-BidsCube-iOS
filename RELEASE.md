# Release 1.1.7

## Summary

Dual CocoaPods distribution at the same version:

| Pod | Minimum iOS | Video | Module name |
| --- | ---: | --- | --- |
| `BidscubeSDKAppLovin` | 15.0 | Google IMA VAST | `BidscubeSDK` |
| `BidscubeSDKAppLovinLegacy` | 14.0 | AVPlayer VAST | `BidscubeSDK` |

Both pods ship the same MAX adapter class: `ALBidscubeMediationAdapter`.

> Install **only one** Bidscube AppLovin pod per target. Do not mix modern and legacy pods in the same target.

### What changed in 1.1.7

- **HTTP 414 fix:** `BidscubeSDK.buildRequestURL` now respects `SDKConfig.enableSKAdNetwork`. The MAX adapter already sets `enableSKAdNetwork(false)`, but ad request URLs still appended every `SKAdNetworkItems` entry from the host app `Info.plist` as `skadnet` query parameters, producing URLs over 8 KB and nginx **414 Request-URI Too Large** on production apps.
- `URLBuilder.buildAdRequestURL` default for `includeSKAdNetworks` is now `false`, matching `SDKConfig.Builder` default.

See [CHANGELOG.md](CHANGELOG.md) for full history.

## Publish checklist

1. **Review diff** — SDK, adapter, both root podspecs, docs, `bidscubeSdk/` sources.
2. **Verify spec layout** — `./scripts/sync-cocoapods-spec.sh` and confirm:
   - `BidscubeSDKAppLovin/1.1.7/BidscubeSDKAppLovin.podspec`
   - `BidscubeSDKAppLovinLegacy/1.1.7/BidscubeSDKAppLovinLegacy.podspec`
3. **Lint** — `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings` and `pod lib lint BidscubeSDKAppLovinLegacy.podspec --allow-warnings`
4. **Unit tests** — `./scripts/run-unit-tests.sh`
5. **Commit** on `main`, including both `1.1.7` spec folders.
6. **Tag and push** — `git tag v1.1.7 && git push origin main && git push origin v1.1.7`
7. **CI** — GitHub Actions `CI` and `Publish SDK` workflows run on push/tag.

### Pre-release local test

Modern (`BidscubeSDKAppLovin`, iOS 15+):

```ruby
platform :ios, '15.0'
pod 'BidscubeSDKAppLovin', :path => '/path/to/AppLovin-SDK-for-BidsCube-iOS'
```

Legacy (`BidscubeSDKAppLovinLegacy`, iOS 14+):

```ruby
platform :ios, '14.0'
pod 'BidscubeSDKAppLovinLegacy', :path => '/path/to/AppLovin-SDK-for-BidsCube-iOS'
```

Or use the sibling **`BidscubeSDKAppLovinTestApp`** next to this repository for full MAX + direct SDK QA.

## Integrator upgrade

### Modern (recommended, iOS 15+)

```ruby
platform :ios, '15.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovin', '1.1.7'
end
```

Pulls `AppLovinSDK` (`~> 13.2`) and `GoogleAds-IMA-iOS-SDK` (`~> 3.32.0`) transitively.

### Legacy (iOS 14+)

```ruby
platform :ios, '14.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovinLegacy', '1.1.7'
end
```

Pulls `AppLovinSDK` (`~> 13.2`) only — **no Google IMA**. On iOS 14, pin `AppLovinSDK` **13.2.x** if needed.

### From 1.1.5 or earlier

Update the pod version to **1.1.7** and run `pod install --repo-update`. No API migration required.

## Git tag

```bash
git tag v1.1.6
git push origin main
git push origin v1.1.6
```

## Post-release

- Confirm GitHub Release created by `Publish SDK` workflow.
- Notify integrators: same dual-pod layout, **1.1.7** for both modern and legacy.
