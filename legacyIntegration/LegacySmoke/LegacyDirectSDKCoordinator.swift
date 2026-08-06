import BidscubeSDK
import Combine
import UIKit

@MainActor
final class LegacyDirectSDKCoordinator: NSObject, ObservableObject, AdCallback {
    @Published private(set) var sdkReady = false
    @Published private(set) var logLines: [String] = []
    @Published private(set) var inlineBannerView: UIView?
    @Published private(set) var inlineNativeView: UIView?

    func bootstrapDirectSDK() {
        guard !sdkReady else { return }

        TestAppConfiguration.applyOptionalSSPEnvironment()
        if !BidscubeSDK.isInitialized() {
            BidscubeSDK.initialize()
        }
        sdkReady = BidscubeSDK.isInitialized()
        appendLog(sdkReady ? "BidscubeSDK initialized (legacy AVPlayer)." : "BidscubeSDK init failed.")
        loadInlineBanner()
        loadInlineNative()
    }

    func loadInlineBanner() {
        guard sdkReady else { return }
        appendLog("Loading inline banner \(TestAppConfiguration.bannerPlacementId)…")
        let banner = BidscubeSDK.getBannerAdView(
            TestAppConfiguration.bannerPlacementId,
            position: .footer,
            callback: self
        )
        banner.setBannerDimensions(width: 320, height: 50)
        inlineBannerView = banner
    }

    func loadInlineNative() {
        guard sdkReady else { return }
        appendLog("Loading inline native \(TestAppConfiguration.nativePlacementId)…")
        let native = BidscubeSDK.getNativeAdView(
            TestAppConfiguration.nativePlacementId,
            width: 320,
            height: 250,
            self
        )
        inlineNativeView = native
    }

    func reloadInlineAds() {
        loadInlineBanner()
        loadInlineNative()
    }

    func showVideoAd() {
        guard let host = presentationHost() else {
            appendLog("No presenter UIViewController.")
            return
        }
        BidscubeSDK.setDisplayViewController(host)
        appendLog("Presenting video \(TestAppConfiguration.videoPlacementId)…")
        BidscubeSDK.showVideoAd(from: host, placementId: TestAppConfiguration.videoPlacementId, callback: self)
    }

    func showNativeAd() {
        guard let host = presentationHost() else {
            appendLog("No presenter UIViewController.")
            return
        }
        BidscubeSDK.setDisplayViewController(host)
        appendLog("Presenting native \(TestAppConfiguration.nativePlacementId)…")
        BidscubeSDK.showNativeAd(
            from: host,
            placementId: TestAppConfiguration.nativePlacementId,
            width: 320,
            height: 480,
            callback: self
        )
    }

    func onAdLoading(_ placementId: String) { appendLog("loading \(placementId)") }
    func onAdLoaded(_ placementId: String) { appendLog("loaded \(placementId)") }
    func onAdDisplayed(_ placementId: String) { appendLog("displayed \(placementId)") }
    func onAdClicked(_ placementId: String) { appendLog("clicked \(placementId)") }
    func onAdClosed(_ placementId: String) { appendLog("closed \(placementId)") }
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {
        appendLog("failed \(placementId): \(errorCode) \(errorMessage)")
    }
    func onVideoAdStarted(_ placementId: String) { appendLog("video started \(placementId)") }
    func onVideoAdCompleted(_ placementId: String) { appendLog("video completed \(placementId)") }
    func onVideoAdSkipped(_ placementId: String) { appendLog("video skipped \(placementId)") }
    func onVideoAdSkippable(_ placementId: String) { appendLog("video skippable \(placementId)") }

    private func appendLog(_ message: String) {
        let line = "[direct] \(message)"
        logLines.insert(line, at: 0)
        if logLines.count > 30 { logLines.removeLast() }
        print(line)
    }

    private func presentationHost() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes.flatMap(\.windows).first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        if let nav = top as? UINavigationController { return nav.visibleViewController }
        return top
    }
}
