import bidscubeSdk
import StoreKit
import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

final class TestAdDelegate: AdCallback, ConsentCallback {
    func onAdLoading(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Ad loading: \(placementId)")
    }

    func onAdLoaded(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Ad loaded: \(placementId)")
    }

    func onAdDisplayed(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Ad displayed: \(placementId)")

        // Track ad view with SKAdNetwork
        if BidscubeSDK.isSKAdNetworkAvailable() {
            BidscubeSDK.trackAdView(completion: { success in
                if success {
                    SDKLogger.d("TestAdDelegate", "SKAdNetwork: Ad view tracked")
                }
            })
        }
    }

    func onAdClicked(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Ad clicked: \(placementId)")

        // Track ad click with SKAdNetwork
        if BidscubeSDK.isSKAdNetworkAvailable() {
            BidscubeSDK.trackAdClick(completion: { success in
                if success {
                    SDKLogger.d("TestAdDelegate", "SKAdNetwork: Ad click tracked")
                }
            })
        }
    }

    func onAdClosed(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Ad closed: \(placementId)")
    }

    func onAdFailed(_ placementId: String, errorCode _: Int, errorMessage: String) {
        SDKLogger.e("TestAdDelegate", "Ad failed: \(placementId) - \(errorMessage) The ad type could be mismatch, try different placementId")
    }

    func onVideoAdStarted(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Video ad started: \(placementId)")
    }

    func onVideoAdCompleted(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Video ad completed: \(placementId)")
    }

    func onVideoAdSkipped(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Video ad skipped: \(placementId)")
    }

    func onVideoAdSkippable(_ placementId: String) {
        SDKLogger.d("TestAdDelegate", "Video ad skippable: \(placementId)")
    }

    func onInstallButtonClicked(_ placementId: String, buttonText: String) {
        SDKLogger.d("TestAdDelegate", "Install button clicked: \(placementId) - \(buttonText)")
    }

    func onConsentInfoUpdated() {
        SDKLogger.d("TestAdDelegate", "Consent info updated successfully")
    }

    func onConsentInfoUpdateFailed(_ error: Error) {
        SDKLogger.w("TestAdDelegate", "Consent info update failed: \(error.localizedDescription)")
    }

    func onConsentFormShown() {
        SDKLogger.d("TestAdDelegate", "Consent form shown")
    }

    func onConsentFormError(_ error: Error) {
        SDKLogger.w("TestAdDelegate", "Consent form error: \(error.localizedDescription)")
    }

    func onConsentGranted() {
        SDKLogger.d("TestAdDelegate", "Consent granted")
    }

    func onConsentDenied() {
        SDKLogger.d("TestAdDelegate", "Consent denied")
    }

    func onConsentNotRequired() {
        SDKLogger.d("TestAdDelegate", "Consent not required")
    }

    func onConsentStatusChanged(_ hasConsent: Bool) {
        SDKLogger.d("TestAdDelegate", "Consent status changed: \(hasConsent)")
    }
}

struct ContentView: View {
    private let delegate = TestAdDelegate()

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("BidsCubeTestLauncher").font(.system(size: 22, weight: .bold))
                Text("Select test view to launch:").foregroundColor(Color.gray)

                NavigationLink(destination: SDKTestView()) {
                    Text("SDK Test View")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: 0x4CAF50))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }

                NavigationLink(destination: ConsentTestView()) {
                    Text("Consent Test View")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: 0xFF9800))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }

                NavigationLink(destination: WindowedAdTestView()) {
                    Text("Windowed Ad View")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: 0x2196F3))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }

                NavigationLink(destination: SKAdNetworkTestView()) {
                    Text("SKAdNetwork Test")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: 0x9C27B0))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }

                NavigationLink(destination: CustomAdRenderView()) {
                    Text("Custom Ad Render (override demo)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding()
            .onAppear {
                BidscubeSDK.requestConsentInfoUpdate(callback: delegate)
            }
        }
    }
}

struct RepresentedView: UIViewRepresentable {
    let make: () -> UIView
    func makeUIView(context _: Context) -> UIView { make() }
    func updateUIView(_: UIView, context _: Context) {}
}
