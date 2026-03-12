# ``bidscubeSdk``

A lightweight iOS SDK for displaying image, video, and native ads with optional consent handling. Mirrors the Android API for easy cross‑platform integration.

## Overview

- Initialize once with `SDKConfig`
- Optional consent flow (GDPR/CCPA)
- Show ads or obtain embeddable views
- Manual ad positioning override

## Quick Start

### Initialize

```swift
import bidscubeSdk

let config = SDKConfig.Builder()
    .enableLogging(true)
    .enableDebugMode(false)
    .defaultAdTimeout(30_000)
    .defaultAdPosition(.unknown)
    .build()

BidscubeSDK.initialize(config: config)
```

### Show an Image Ad

```swift
class MyAdDelegate: AdCallback {
    func onAdLoading(_ placementId: String) {}
    func onAdLoaded(_ placementId: String) {}
    func onAdDisplayed(_ placementId: String) {}
    func onAdClicked(_ placementId: String) {}
    func onAdClosed(_ placementId: String) {}
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {}
}

let callback = MyAdDelegate()
BidscubeSDK.showImageAd("20212", callback)
```

### Get an Ad View

```swift
let view = BidscubeSDK.getImageAdView("20212", callback)
```

### Video and Native

```swift
BidscubeSDK.showVideoAd("20213", callback)
BidscubeSDK.showSkippableVideoAd("20213", "Install Now", callback)
let nativeView = BidscubeSDK.getNativeAdView("20214", callback)
```

## Ad Positioning

- Response-based position is honored when available
- Manual override:

```swift
BidscubeSDK.setAdPosition(.header)
let effective = BidscubeSDK.getEffectiveAdPosition()
```

Positions:
- `.unknown`, `.aboveTheFold`, `.dependOnScreenSize`, `.belowTheFold`, `.header`, `.footer`, `.sidebar`, `.fullScreen`

## Consent (Stubbed)

```swift
BidscubeSDK.requestConsentInfoUpdate(callback: self)
// In callback, if required, present form
BidscubeSDK.showConsentForm(self)
```

Helpers:

```swift
_ = BidscubeSDK.isConsentRequired()
_ = BidscubeSDK.hasAdsConsent()
_ = BidscubeSDK.hasAnalyticsConsent()
_ = BidscubeSDK.getConsentStatusSummary()
```

## NativeAdView customization

```swift
let nativeView = NativeAdView()
nativeView.setCTAText("Shop Now")
nativeView.setCustomStyle(.white, .black, .systemBlue)
nativeView.setCTAButton("Install", .systemBlue, .white)
```

## Cleanup

```swift
BidscubeSDK.cleanup()
```