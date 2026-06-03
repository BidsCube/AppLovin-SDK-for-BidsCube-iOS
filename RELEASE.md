# Release 1.0.5

## Summary

Stable error handling aligned with Android SDK 1.2.7: HTTP 204 no-fill, main-thread `onAdFailed`, and MAX view-controller binding.

## Publish checklist

1. **Review diff** — `git diff` (SDK, adapter, podspecs, docs).
2. **Verify spec layout** — `./scripts/sync-cocoapods-spec.sh` and confirm `BidscubeSDKAppLovin/1.0.5/BidscubeSDKAppLovin.podspec` exists.
3. **Commit** on `main` (or release branch), including the `1.0.5` spec folder.
4. **Tag and push** — `git tag v1.0.5 && git push origin main && git push origin v1.0.5`
5. **CI** — GitHub Actions `Publish SDK` runs on tag push (`pod lib lint`, GitHub Release).
6. **Local lockfile** (optional) — after the tag is on GitHub: `pod install --repo-update` in apps using the in-repo spec source.

### Pre-release local test (before tag is on GitHub)

```ruby
pod 'BidscubeSDKAppLovin', :path => '/path/to/bidscube-sdk-ios'
```

Or lint the podspec: `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings`

## Integrator upgrade

```ruby
pod 'BidscubeSDKAppLovin', '1.0.5'
```

```bash
pod install --repo-update
```

Handle `onAdFailed` with `AdErrorCode.noFill` (204) as a normal no-fill, not a crash.

## Related

- [CHANGELOG.md](CHANGELOG.md)
- [docs/errors.md](docs/errors.md)
- [README.md](README.md)
