# Bidscube SDK — error codes

**SDK 1.1.0+**

When an ad request or display fails, the SDK invokes `AdCallback.onAdFailed(placementId, errorCode, errorMessage)`.  
All `errorMessage` strings are **English** and safe to log or forward to mediation adapters.

Constants live in `AdErrorCode`.

---

## Error code reference

| Code | Constant | Summary | Typical cause |
|------|----------|---------|---------------|
| **-1** | `unknown` | Unknown error | Unclassified failure; check `errorMessage` |
| **204** | `noFill` | No ad fill | SSP returned HTTP **204 No Content** (no demand for this request) |
| **1001** | `httpError` | Ad server HTTP error | Non-2xx HTTP status (except 204) |
| **1002** | `invalidResponse` | Invalid ad server response | Response body could not be parsed |
| **1003** | `emptyAdm` | Empty ad markup | HTTP 200 but ADM field is empty |
| **1004** | `noViewController` | View controller required | No host view controller was bound before show |
| **1005** | `networkError` | Network error | Timeout, connection failure, I/O exception |
| **1006** | `displayError` | Ad display error | Unexpected failure while building or showing the ad UI |

Use `AdErrorCode.describe(errorCode)` for a short English label in logs.

---

## Example messages

| Code | Example `errorMessage` |
|------|------------------------|
| 204 | `No ad fill: ad server returned HTTP 204 (No Content)` |
| 1001 | `HTTP error: 500 — …` |
| 1002 | `Failed to parse ad server response` |
| 1004 | `A view controller is required to display ads. Pass a UIViewController when showing ads (for example from the MAX adapter show callback).` |
| 1005 | `Network error: …` |

---

## AppLovin MAX mediation

The Bidscube adapter forwards SDK failures to MAX **display failed** callbacks using the same numeric `errorCode` and English `errorMessage`.

- **`204` / no fill** — not a crash; Bidscube had no ad for the placement.
- **`1004` / no view controller** — should not occur when using the official adapter (the show `UIViewController` is bound via `BidscubeSDK.setDisplayViewController`).

---

## Standalone SDK

```swift
BidscubeSDK.showImageAd(from: viewController, placementId: "21492", callback: self)

func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
    print("placement=\(placementId) code=\(errorCode) (\(AdErrorCode.describe(errorCode))) msg=\(errorMessage)")
}
```

Call `BidscubeSDK.setDisplayViewController(_:)` before show methods if you do not pass an explicit presenter.

---

## Related

- [Main README](../README.md)
- [CHANGELOG](../CHANGELOG.md)
