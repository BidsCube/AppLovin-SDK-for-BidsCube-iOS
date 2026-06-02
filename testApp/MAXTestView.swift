import AppLovinSDK
import SwiftUI

struct MAXTestView: View {
    @EnvironmentObject private var coordinator: MAXAdCoordinator

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statusSection
                    adControlsSection
                    adPreviewSection
                    logSection
                }
                .padding()
            }
            .navigationTitle("Bidscube MAX Test")
            .onAppear {
                TestAppConfiguration.applyOptionalSSPEnvironment()
                coordinator.bootstrapMAX()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(coordinator.maxReady ? "MAX: ready" : "MAX: not initialized")
                .font(.headline)
            Text("Configure ad unit IDs via Xcode scheme environment variables or Info.plist.")
                .font(.footnote)
                .foregroundColor(.secondary)
            Group {
                configRow("Banner", TestAppConfiguration.bannerAdUnitId)
                configRow("MREC", TestAppConfiguration.mrecAdUnitId)
                configRow("Interstitial", TestAppConfiguration.interstitialAdUnitId)
                configRow("Rewarded", TestAppConfiguration.rewardedAdUnitId)
                configRow("Native", TestAppConfiguration.nativeAdUnitId)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var adControlsSection: some View {
        VStack(spacing: 10) {
            Button("Reload all ads", action: coordinator.reloadAll)
                .buttonStyle(.borderedProminent)

            HStack {
                Button("Show Interstitial", action: coordinator.showInterstitial)
                Button("Show Rewarded", action: coordinator.showRewarded)
            }
            .buttonStyle(.bordered)

            Button("Load Native", action: coordinator.loadNative)
                .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var adPreviewSection: some View {
        if let banner = coordinator.makeBannerView() {
            Text("Banner").font(.subheadline.bold())
            MAAdViewContainer(adView: banner)
                .frame(height: 50)
        }

        if let mrec = coordinator.makeMRECView() {
            Text("MREC").font(.subheadline.bold())
            MAAdViewContainer(adView: mrec)
                .frame(height: 250)
        }

        if coordinator.makeNativeAdView() != nil {
            Text("Native").font(.subheadline.bold())
            NativeAdContainer(nativeView: coordinator.makeNativeAdView())
                .frame(minHeight: 120)
        }
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log").font(.headline)
            ForEach(coordinator.logLines, id: \.self) { line in
                Text(line)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func configRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .frame(width: 90, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
        }
    }
}
