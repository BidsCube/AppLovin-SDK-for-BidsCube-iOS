# Release 1.1.5

## Summary

Dual CocoaPods distribution at the same version:

| Pod | Minimum iOS | Video | Module name |
| --- | ---: | --- | --- |
| `BidscubeSDKAppLovin` | 15.0 | Google IMA VAST | `BidscubeSDK` |
| `BidscubeSDKAppLovinLegacy` | 14.0 | AVPlayer VAST | `BidscubeSDK` |

Both pods ship the same MAX adapter class: `ALBidscubeMediationAdapter`.

> Install **only one** Bidscube AppLovin pod per target. Do not mix modern and legacy pods in the same target.

### What changed in 1.1.5

- In-repo test / integration projects are **gitignored** (local QA only). Use the sibling **`BidscubeSDKAppLovinTestApp`** or a `:path` pod in your own app for smoke tests.
- CI validates podspec lint, SwiftPM resolve, and `spmUnitTests` only.
- Documentation updated for **1.1.5**; no functional SDK API changes vs **1.1.5**.

See [CHANGELOG.md](CHANGELOG.md) for full history.

## Publish checklist

1. **Review diff** — SDK, adapter, both root podspecs, docs, `bidscubeSdk/` sources.
2. **Verify spec layout** — `./scripts/sync-cocoapods-spec.sh` and confirm:
   - `BidscubeSDKAppLovin/1.1.5/BidscubeSDKAppLovin.podspec`
   - `BidscubeSDKAppLovinLegacy/1.1.5/BidscubeSDKAppLovinLegacy.podspec`
3. **Lint** — `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings` and `pod lib lint BidscubeSDKAppLovinLegacy.podspec --allow-warnings`
4. **Unit tests** — `./scripts/run-unit-tests.sh`
5. **Commit** on `main`, including both `1.1.5` spec folders.
6. **Tag and push** — `git tag v1.1.5 && git push origin main && git push origin v1.1.5`
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
  pod 'BidscubeSDKAppLovin', '1.1.5'
end
```

Pulls `AppLovinSDK` (`~> 13.6.0`) and `GoogleAds-IMA-iOS-SDK` (`~> 3.32.0`) transitively.

### Legacy (iOS 14+)

```ruby
platform :ios, '14.0'
use_frameworks!

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'YourApp' do
  pod 'BidscubeSDKAppLovinLegacy', '1.1.5'
end
```

Pulls `AppLovinSDK` (`~> 13.6.0`) only — **no Google IMA**.

### From 1.1.4

Update the pod version and run `pod install --repo-update`. No API migration required.

## Git tag

```bash
git tag v1.1.5
git push origin main
git push origin v1.1.5
```

## Post-release

- Confirm GitHub Release created by `Publish SDK` workflow.
- Notify integrators: same dual-pod layout, **1.1.5** for both modern and legacy.
