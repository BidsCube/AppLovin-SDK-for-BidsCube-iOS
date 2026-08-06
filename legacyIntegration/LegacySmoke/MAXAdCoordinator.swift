import AppLovinSDK
import Combine
import Foundation
import UIKit

@MainActor
final class MAXAdCoordinator: NSObject, ObservableObject {
    @Published private(set) var maxReady = false
    @Published private(set) var logLines: [String] = []

    private var interstitial: MAInterstitialAd?
    private var rewarded: MARewardedAd?
    private var bannerView: MAAdView?
    private var mrecView: MAAdView?
    private var nativeLoader: MANativeAdLoader?
    private var nativeAdView: UIView?

    func bootstrapMAX() {
        guard TestAppConfiguration.isMAXConfigured else {
            appendLog("Set APPLOVIN_SDK_KEY (env or Info.plist AppLovinSdkKey).")
            return
        }
        guard !maxReady else { return }

        let initConfig = ALSdkInitializationConfiguration(
            sdkKey: TestAppConfiguration.applovinSDKKey
        ) { builder in
            builder.mediationProvider = ALMediationProviderMAX
        }

        appendLog("Initializing AppLovin MAX…")
        ALSdk.shared().initialize(with: initConfig) { [weak self] _ in
            Task { @MainActor in
                self?.maxReady = true
                self?.appendLog("MAX initialized.")
                self?.prepareAds()
            }
        }
    }

    func prepareAds() {
        prepareInterstitial()
        prepareRewarded()
        prepareBanner()
        prepareMREC()
        prepareNativeLoader()
    }

    func showInterstitial() {
        guard let interstitial else {
            appendLog("Interstitial not ready.")
            return
        }
        if interstitial.isReady {
            interstitial.show()
        } else {
            appendLog("Interstitial loading…")
            interstitial.load()
        }
    }

    func showRewarded() {
        guard let rewarded else {
            appendLog("Rewarded not ready.")
            return
        }
        if rewarded.isReady {
            rewarded.show()
        } else {
            appendLog("Rewarded loading…")
            rewarded.load()
        }
    }

    func reloadAll() {
        interstitial?.load()
        rewarded?.load()
        bannerView?.loadAd()
        mrecView?.loadAd()
        if nativeLoader != nil {
            loadNative()
        }
        appendLog("Reload requested for all units.")
    }

    func makeBannerView() -> MAAdView? {
        bannerView
    }

    func makeMRECView() -> MAAdView? {
        mrecView
    }

    func makeNativeAdView() -> UIView? {
        nativeAdView
    }

    func loadNative() {
        guard let nativeLoader else {
            appendLog("Native loader not configured.")
            return
        }
        appendLog("Loading native ad…")
        nativeLoader.loadAd()
    }

    private func prepareInterstitial() {
        let unitId = TestAppConfiguration.interstitialAdUnitId
        guard !unitId.isEmpty else { return }
        let ad = MAInterstitialAd(adUnitIdentifier: unitId)
        ad.delegate = self
        interstitial = ad
        ad.load()
        appendLog("Interstitial load started (\(unitId)).")
    }

    private func prepareRewarded() {
        let unitId = TestAppConfiguration.rewardedAdUnitId
        guard !unitId.isEmpty else { return }
        let ad = MARewardedAd.shared(withAdUnitIdentifier: unitId)
        ad.delegate = self
        rewarded = ad
        ad.load()
        appendLog("Rewarded load started (\(unitId)).")
    }

    private func prepareBanner() {
        let unitId = TestAppConfiguration.bannerAdUnitId
        guard !unitId.isEmpty else { return }
        let ad = MAAdView(adUnitIdentifier: unitId, adFormat: .banner)
        ad.delegate = self
        bannerView = ad
        ad.loadAd()
        appendLog("Banner load started (\(unitId)).")
    }

    private func prepareMREC() {
        let unitId = TestAppConfiguration.mrecAdUnitId
        guard !unitId.isEmpty else { return }
        let ad = MAAdView(adUnitIdentifier: unitId, adFormat: .mrec)
        ad.delegate = self
        mrecView = ad
        ad.loadAd()
        appendLog("MREC load started (\(unitId)).")
    }

    private func prepareNativeLoader() {
        let unitId = TestAppConfiguration.nativeAdUnitId
        guard !unitId.isEmpty else { return }
        let loader = MANativeAdLoader(adUnitIdentifier: unitId)
        loader.nativeAdDelegate = self
        nativeLoader = loader
        appendLog("Native loader ready (\(unitId)).")
    }

    fileprivate func appendLog(_ message: String) {
        let line = "[\(Self.timeStamp())] \(message)"
        logLines.insert(line, at: 0)
        if logLines.count > 40 {
            logLines.removeLast()
        }
        print(line)
    }

    private static func timeStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

extension MAXAdCoordinator: MAAdViewAdDelegate {
    nonisolated func didExpand(_ ad: MAAd) {
        Task { @MainActor in appendLog("Expanded: \(ad.adUnitIdentifier)") }
    }

    nonisolated func didCollapse(_ ad: MAAd) {
        Task { @MainActor in appendLog("Collapsed: \(ad.adUnitIdentifier)") }
    }
}

extension MAXAdCoordinator: MAAdDelegate {
    nonisolated func didLoad(_ ad: MAAd) {
        Task { @MainActor in appendLog("Loaded: \(ad.adUnitIdentifier)") }
    }

    nonisolated func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        Task { @MainActor in appendLog("Load failed \(adUnitIdentifier): \(error.message)") }
    }

    nonisolated func didDisplay(_ ad: MAAd) {
        Task { @MainActor in appendLog("Displayed: \(ad.adUnitIdentifier)") }
    }

    nonisolated func didHide(_ ad: MAAd) {
        Task { @MainActor in
            appendLog("Hidden: \(ad.adUnitIdentifier)")
            if ad.adUnitIdentifier == TestAppConfiguration.interstitialAdUnitId {
                interstitial?.load()
            } else if ad.adUnitIdentifier == TestAppConfiguration.rewardedAdUnitId {
                rewarded?.load()
            }
        }
    }

    nonisolated func didClick(_ ad: MAAd) {
        Task { @MainActor in appendLog("Clicked: \(ad.adUnitIdentifier)") }
    }

    nonisolated func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Task { @MainActor in appendLog("Display failed \(ad.adUnitIdentifier): \(error.message)") }
    }
}

extension MAXAdCoordinator: MARewardedAdDelegate {
    nonisolated func didRewardUser(for ad: MAAd, with reward: MAReward) {
        Task { @MainActor in appendLog("Reward: \(reward.label) x\(reward.amount)") }
    }
}

extension MAXAdCoordinator: MANativeAdDelegate {
    nonisolated func didLoadNativeAd(_ nativeAdView: MANativeAdView?, for ad: MAAd) {
        Task { @MainActor in
            self.nativeAdView = nativeAdView
            appendLog("Native loaded: \(ad.adUnitIdentifier)")
        }
    }

    nonisolated func didFailToLoadNativeAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        Task { @MainActor in appendLog("Native load failed \(adUnitIdentifier): \(error.message)") }
    }

    nonisolated func didClickNativeAd(_ ad: MAAd) {
        Task { @MainActor in appendLog("Native clicked: \(ad.adUnitIdentifier)") }
    }
}
