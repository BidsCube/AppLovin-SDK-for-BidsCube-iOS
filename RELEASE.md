# Release 1.1.1

## Summary

Publisher `user_id` support for SSP ad requests and postback attribution. Set at SDK init or via MAX server parameters (`user_id` / `userId`).

## Publish checklist

1. **Review diff** — `git diff` (SDK, adapter, podspecs, docs).
2. **Verify spec layout** — `./scripts/sync-cocoapods-spec.sh` and confirm `BidscubeSDKAppLovin/1.1.1/BidscubeSDKAppLovin.podspec` exists.
3. **Lint** — `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings`
4. **Commit** on `main`, including the `1.1.1` spec folder.
5. **Tag and push** — `git tag v1.1.1 && git push max main && git push max v1.1.1`
6. **CI** — GitHub Actions `Publish SDK` runs on tag push.

### Pre-release local test

```ruby
pod 'BidscubeSDKAppLovin', :path => '/path/to/AppLovin-SDK-for-BidsCube-iOS'
```

## Integrator upgrade

```ruby
platform :ios, '15.0'
pod 'BidscubeSDKAppLovin', '1.1.1'
```

### New: publisher user id

```swift
BidscubeSDK.initialize(config: SDKConfig.Builder().userId("your-user-id").build())
// or after login:
BidscubeSDK.setUserId("your-user-id")
```

MAX dashboard server parameter: `user_id` (or `userId`).

## Related

- [CHANGELOG.md](CHANGELOG.md)
- [README.md](README.md)
