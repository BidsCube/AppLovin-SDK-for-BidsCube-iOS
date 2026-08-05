# Release 1.2.0

## Summary

Fullscreen video lifecycle: `autoClose` (default `false`), VAST Companion end cards, skip countdown (default 15 s), centralized dismiss.

## Publish checklist

1. **Review diff** — `git diff` (SDK, adapter, podspecs, docs).
2. **Verify spec layout** — `./scripts/sync-cocoapods-spec.sh` and confirm `BidscubeSDKAppLovin/1.2.0/BidscubeSDKAppLovin.podspec` exists.
3. **Lint** — `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings`
4. **Commit** on `main`, including the `1.2.0` spec folder.
5. **Tag and push** — `git tag v1.2.0 && git push max main && git push max v1.2.0`
6. **CI** — GitHub Actions `Publish SDK` runs on tag push.

### Pre-release local test

```ruby
pod 'BidscubeSDKAppLovin', :path => '/path/to/AppLovin-SDK-for-BidsCube-iOS'
```

## Integrator upgrade

```ruby
platform :ios, '15.0'
pod 'BidscubeSDKAppLovin', '1.2.0'
```

### New: autoClose (default false)

```swift
BidscubeSDK.initialize(config: SDKConfig.Builder().autoClose(false).build())
```

MAX dashboard init server parameter: `auto_close` (or `autoClose`).

### Skip overlay

Default **15 s** countdown before Skip is enabled; overridden by VAST `Linear@skipoffset` when present.

## Related

- [CHANGELOG.md](CHANGELOG.md)
- [README.md](README.md)
