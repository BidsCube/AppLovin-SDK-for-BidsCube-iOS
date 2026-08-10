# Release 1.1.10

Publisher-focused logging fix: all banner/image code paths now emit diagnostics under the unified **`BidscubeMAX`** console tag when logging is enabled.

## What changed in 1.1.10

- **`getBannerAdView` / banner APIs** use `Logger.imageAd` → duplicated to `[BidscubeMAX]` (same as MAX `getImageAdView` path).
- **`ImageAdView` / `BannerAdView`** no longer use raw `print()`; HTML render, click URL extraction, and clicks go through `Logger` and respect `enable_logging`.
- **Docs:** [applovin-adapter/README.md — Publisher logging](applovin-adapter/README.md#publisher-logging-bidscubemax).

## Release checklist

1. Bump `Constants.sdkVersion` and root `.podspec` files to **1.1.10**.
2. Update `CHANGELOG.md`, `README.md`, `applovin-adapter/README.md`.
3. Run `./scripts/sync-cocoapods-spec.sh` (creates `BidscubeSDKAppLovin/1.1.10/` and `BidscubeSDKAppLovinLegacy/1.1.10/`).
4. **Commit** on `main`, including both `1.1.10` spec folders.
5. **Tag and push** — `git tag v1.1.10 && git push max main && git push max v1.1.10`

## Integrator upgrade

```ruby
pod 'BidscubeSDKAppLovin', '1.1.10'
# or
pod 'BidscubeSDKAppLovinLegacy', '1.1.10'
```

```bash
pod install --repo-update
```

No API migration required. Enable logging per [Publisher logging guide](applovin-adapter/README.md#publisher-logging-bidscubemax).
