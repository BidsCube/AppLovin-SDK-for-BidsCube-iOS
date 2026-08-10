# Release 1.1.9

## Summary

Dual CocoaPods distribution at the same version:

| Pod | Minimum iOS | Video | Module name |
| --- | ---: | --- | --- |
| `BidscubeSDKAppLovin` | 15.0 | Google IMA VAST | `BidscubeSDK` |
| `BidscubeSDKAppLovinLegacy` | 14.0 | AVPlayer VAST | `BidscubeSDK` |

Both pods ship the same MAX adapter class: `ALBidscubeMediationAdapter`.

> Install **only one** Bidscube AppLovin pod per target. Do not mix modern and legacy pods in the same target.

### What changed in 1.1.9

- **MAX banner / MREC / leader (Android parity):** all AdView formats use `BidscubeSDK.getImageAdView` (not `getBannerAdView`).
- **SSP HTTP timeout:** 10s ad request timeout (matches Android `HttpProvider`) — reduces MAX `-5101` adapter timeouts on slow SSP responses.

See [CHANGELOG.md](CHANGELOG.md) for full history.

## Publish checklist

1. **Review diff** — SDK, adapter, both root podspecs, docs, `bidscubeSdk/` sources.
2. **Verify spec layout** — `./scripts/sync-cocoapods-spec.sh` and confirm:
   - `BidscubeSDKAppLovin/1.1.9/BidscubeSDKAppLovin.podspec`
   - `BidscubeSDKAppLovinLegacy/1.1.9/BidscubeSDKAppLovinLegacy.podspec`
3. **Lint** — `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings` and `pod lib lint BidscubeSDKAppLovinLegacy.podspec --allow-warnings`
4. **Unit tests** — `./scripts/run-unit-tests.sh`
5. **Commit** on `main`, including both `1.1.9` spec folders.
6. **Tag and push** — `git tag v1.1.9 && git push max main && git push max v1.1.9`
7. **CI** — GitHub Actions `CI` and `Publish SDK` workflows run on push/tag.

### Pre-release local test

Legacy (`BidscubeSDKAppLovinLegacy`, iOS 14+):

```ruby
platform :ios, '14.0'
pod 'BidscubeSDKAppLovinLegacy', :path => '/path/to/AppLovin-SDK-for-BidsCube-iOS'
```

```bash
./scripts/run-legacy-test-app.sh
```

## Integrator upgrade

### Modern (recommended, iOS 15+)

```ruby
platform :ios, '15.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovin', '1.1.9'
end
```

### Legacy (iOS 14+)

```ruby
platform :ios, '14.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovinLegacy', '1.1.9'
end
```

### From 1.1.8

Update the pod version to **1.1.9** and run `pod install --repo-update`. No API migration required.

## Git tag

```bash
git tag v1.1.9
git push max main
git push max v1.1.9
```

## Post-release

- Confirm GitHub Release created by `Publish SDK` workflow.
- Notify integrators: same dual-pod layout, **1.1.9** for both modern and legacy.
