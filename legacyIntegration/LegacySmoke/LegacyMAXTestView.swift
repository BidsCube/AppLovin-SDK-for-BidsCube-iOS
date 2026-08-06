import AppLovinSDK
import BidscubeSDK
import SwiftUI

struct LegacyMAXTestView: View {
    @EnvironmentObject private var maxCoordinator: MAXAdCoordinator
    @EnvironmentObject private var directCoordinator: LegacyDirectSDKCoordinator

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    legacyHeaderSection
                    directSDKSection
                    Divider()
                    maxStatusSection
                    maxControlsSection
                    maxPreviewSection
                    combinedLogSection
                }
                .padding()
            }
            .navigationTitle("Legacy Test App")
            .onAppear {
                TestAppConfiguration.applyOptionalSSPEnvironment()
                directCoordinator.bootstrapDirectSDK()
                maxCoordinator.bootstrapMAX()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var legacyHeaderSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BidscubeSDKAppLovinLegacy")
                .font(.title3.bold())
            Text("SDK \(Constants.sdkVersion) · AVPlayer VAST · iOS 14+")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var directSDKSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Direct SDK API")
                .font(.headline)
            Text(directCoordinator.sdkReady ? "BidscubeSDK: ready" : "BidscubeSDK: initializing…")
                .font(.subheadline)
            Group {
                configRow("Banner", TestAppConfiguration.bannerPlacementId)
                configRow("Video", TestAppConfiguration.videoPlacementId)
                configRow("Native", TestAppConfiguration.nativePlacementId)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            HStack {
                Button("Reload Banner", action: directCoordinator.loadInlineBanner)
                Button("Reload Native", action: directCoordinator.loadInlineNative)
            }
            .padding(.vertical, 4)
            HStack {
                Button("Video", action: directCoordinator.showVideoAd)
                Button("Native FS", action: directCoordinator.showNativeAd)
            }
            .padding(.bottom, 4)

            if let banner = directCoordinator.inlineBannerView {
                Text("Banner preview").font(.subheadline.bold())
                BidscubeBannerContainer(bannerView: banner)
                    .frame(height: 50)
            }

            if let native = directCoordinator.inlineNativeView {
                Text("Native preview").font(.subheadline.bold())
                BidscubeBannerContainer(bannerView: native)
                    .frame(height: 250)
            }
        }
    }

    private var maxStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AppLovin MAX")
                .font(.headline)
            Text(maxStatusText)
                .font(.subheadline)
            Group {
                configRow("Banner", TestAppConfiguration.bannerAdUnitId)
                configRow("MREC", TestAppConfiguration.mrecAdUnitId)
                configRow("Interstitial", TestAppConfiguration.interstitialAdUnitId)
                configRow("Rewarded", TestAppConfiguration.rewardedAdUnitId)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var maxControlsSection: some View {
        VStack(spacing: 10) {
            Button("Reload MAX ads", action: maxCoordinator.reloadAll)
            HStack {
                Button("Interstitial", action: maxCoordinator.showInterstitial)
                Button("Rewarded", action: maxCoordinator.showRewarded)
            }
        }
    }

    @ViewBuilder
    private var maxPreviewSection: some View {
        if let banner = maxCoordinator.makeBannerView() {
            Text("Banner").font(.subheadline.bold())
            MAAdViewContainer(adView: banner).frame(height: 50)
        }
        if let mrec = maxCoordinator.makeMRECView() {
            Text("MREC").font(.subheadline.bold())
            MAAdViewContainer(adView: mrec).frame(height: 250)
        }
    }

    private var combinedLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log").font(.headline)
            ForEach(directCoordinator.logLines + maxCoordinator.logLines, id: \.self) { line in
                Text(line)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var maxStatusText: String {
        if !maxCoordinator.maxReady {
            return "MAX: initializing…"
        }
        if !TestAppConfiguration.isMAXAdsConfigured {
            return "MAX: add MAX_*_AD_UNIT_ID to Info.plist for interstitial/rewarded video"
        }
        return "MAX: ready"
    }

    private func configRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .frame(width: 90, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
        }
    }
}
