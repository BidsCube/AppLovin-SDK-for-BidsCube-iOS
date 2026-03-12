import SwiftUI
import bidscubeSdk

/// Demonstrates overriding SDK rendering via `onAdRenderOverride` and logging the ad markup + position.
struct CustomAdRenderView: View {
    @State private var logs: [String] = []
    @State private var isSDKInitialized = false
    
    private func appendLog(_ message: String) {
        DispatchQueue.main.async {
            logs.insert(message, at: 0)
        }
    }
    
    private func makeDelegate() -> AdCallback {
        CustomAdRenderDelegate { adm, position in
            appendLog("Override render -> position: \(position) adm: \(adm)")
        }
    }
    
    private func initializeSDK() {
        let config = SDKConfig.Builder()
            .enableLogging(true)
            .enableDebugMode(true)
            .defaultAdTimeout(30000)
            .defaultAdPosition(.unknown)
            .build()
        BidscubeSDK.initialize(config: config)
        isSDKInitialized = true
        appendLog("SDK initialized")
    }
    
    private func requestAd(adType: AdType) {
        guard isSDKInitialized else {
            appendLog("SDK not initialized")
            return
        }
        let delegate = makeDelegate()
        switch adType {
        case .image:
            BidscubeSDK.showImageAd("20212", delegate)
            appendLog("Requested Image ad (20212)")
        case .video:
            BidscubeSDK.showVideoAd("20213", delegate)
            appendLog("Requested Video ad (20213)")
        case .native:
            BidscubeSDK.showNativeAd("20214", delegate)
            appendLog("Requested Native ad (20214)")
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Custom Ad Render Override")
                .font(.title2)
                .padding(.top)
            
            Button(action: initializeSDK) {
                Text("Initialize SDK")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            HStack(spacing: 12) {
                Button {
                    requestAd(adType: .image)
                } label: {
                    Text("Override Image")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button {
                    requestAd(adType: .video)
                } label: {
                    Text("Override Video")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button {
                    requestAd(adType: .native)
                } label: {
                    Text("Override Native")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Divider().padding(.vertical, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(logs.indices, id: \.self) { index in
                        Text(logs[index])
                            .font(.footnote)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }
}

private final class CustomAdRenderDelegate: AdCallback {
    private let handler: (_ adm: String, _ position: AdPosition) -> Void
    
    init(handler: @escaping (_ adm: String, _ position: AdPosition) -> Void) {
        self.handler = handler
    }
    
    // MARK: - AdCallback
    func onAdRenderOverride(adm: String, position: AdPosition) {
        handler(adm, position)
    }
    
    // Other callbacks are no-ops for this demo
    func onAdLoading(_ placementId: String) {}
    func onAdLoaded(_ placementId: String) {}
    func onAdDisplayed(_ placementId: String) {}
    func onAdClicked(_ placementId: String) {}
    func onAdClosed(_ placementId: String) {}
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {}
    func onVideoAdStarted(_ placementId: String) {}
    func onVideoAdCompleted(_ placementId: String) {}
    func onVideoAdSkipped(_ placementId: String) {}
    func onVideoAdSkippable(_ placementId: String) {}
    func onInstallButtonClicked(_ placementId: String, buttonText: String) {}
}

#Preview {
    CustomAdRenderView()
}

