# Release 1.1.0

## Summary

Production-ready AppLovin MAX adapter for Bidscube iOS: video interstitial/rewarded with cached load/show, structured signal collection, Native MAX removed, and sibling QA test app.

## Publish checklist

1. **Review diff** — `git diff` (SDK, adapter, podspecs, docs, `.gitattributes`).
2. **Verify spec layout** — `./scripts/sync-cocoapods-spec.sh` and confirm `BidscubeSDKAppLovin/1.1.0/BidscubeSDKAppLovin.podspec` exists.
3. **Lint** — `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings`
4. **Commit** on `main` (or release branch), including the `1.1.0` spec folder and `.gitattributes`.
5. **Tag and push** — `git tag v1.1.0 && git push origin main && git push origin v1.1.0`
6. **CI** — GitHub Actions `Publish SDK` runs on tag push (`pod lib lint`, GitHub Release).
7. **Local lockfile** (optional) — after the tag is on GitHub: `pod install --repo-update` in apps using the in-repo spec source.

### Pre-release local test (before tag is on GitHub)

```ruby
pod 'BidscubeSDKAppLovin', :path => '/path/to/AppLovin-SDK-for-BidsCube-iOS'
```

For MAX integration QA, use the sibling test app at `../BidscubeSDKAppLovinTestApp/` (local `:path` pod dependency).

Or lint the podspec: `pod lib lint BidscubeSDKAppLovin.podspec --allow-warnings`

## Clean release archives

Commit `.gitattributes` (export-ignore for legacy `testApp*` samples) before creating handoff zips.

**SDK source archive** (from repo root):

```bash
git archive --format=zip --output ../AppLovin-SDK-for-BidsCube-iOS-release.zip HEAD
unzip -l ../AppLovin-SDK-for-BidsCube-iOS-release.zip | grep -E '(^|/)(\.git|build/|DerivedData/|Pods/|__MACOSX|\.DS_Store|/\._)' && exit 1 || true
```

**Sibling test app archive** (from `ios/` workspace parent):

```bash
zip -r ../BidscubeSDKAppLovinTestApp.zip BidscubeSDKAppLovinTestApp \
  -x "*.DS_Store" \
  -x "*__MACOSX*" \
  -x "*/._*" \
  -x "*/Pods/*" \
  -x "*/DerivedData/*" \
  -x "*/build/*"
unzip -l ../BidscubeSDKAppLovinTestApp.zip | grep -E "__MACOSX|\.DS_Store|/\._|/Pods/|/DerivedData/|/build/" && exit 1 || true
```

Do not ship archives that contain `.git/`, `build/`, `Pods/`, `__MACOSX/`, or `._*` artifacts.

## Integrator upgrade

**Requires iOS 15.0+** in your app `Podfile` / Xcode deployment target (IMA video dependency).

```ruby
platform :ios, '15.0'
pod 'BidscubeSDKAppLovin', '1.1.0'
```

```bash
pod install --repo-update
```

### Breaking / behavior changes from 1.0.x

- **Native MAX is not supported** — remove Native ad units from Bidscube network config.
- **Interstitial uses video path** — configure MAX interstitial ad units for video, not static/image-only expectations.
- Load caches Bidscube response; show presents from cache (no second network request).

Handle `onAdFailed` with `AdErrorCode.noFill` (204) as a normal no-fill, not a crash.

## Related

- [CHANGELOG.md](CHANGELOG.md)
- [docs/errors.md](docs/errors.md)
- [README.md](README.md)
- Sibling QA app: `../BidscubeSDKAppLovinTestApp/README.md`
