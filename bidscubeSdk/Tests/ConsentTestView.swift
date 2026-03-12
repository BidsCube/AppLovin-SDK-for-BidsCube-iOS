import SwiftUI
import bidscubeSdk

struct ConsentTestView: View {
    @State private var sdkStatus = "SDK Status: Not Initialized"
    @State private var placementId = "20212"
    @State private var isSDKInitialized = false
    @State private var showPlacementIdAlert = false
    @State private var consentStatus = ""
    @State private var currentAdView: AnyView?
    
    private let delegate = TestAdDelegate()
    
    var body: some View {
        ScrollView {
                VStack(spacing: 16) {
                    // Status Text
                    Text(sdkStatus)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom)
                    
                    // Initialize SDK Button
                    Button(action: initializeSDK) {
                        Text("Initialize SDK")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    // Placement ID Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Placement ID Input:")
                            .font(.headline)
                        
                        TextField("Enter placement ID (e.g., 20212)", text: $placementId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    if isSDKInitialized {
                        // Consent Management Section
                        VStack(spacing: 12) {
                            Text("Consent Management")
                                .font(.headline)
                                .padding(.top)
                            
                            Button(action: requestConsentInfoUpdate) {
                                Text("Request Consent Info Update")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: showConsentForm) {
                                Text("Show Consent Form")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: checkConsentRequired) {
                                    Text("Check if Consent Required")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.orange)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: checkAdsConsent) {
                                    Text("Check Ads Consent")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.purple)
                                        .cornerRadius(8)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: checkAnalyticsConsent) {
                                    Text("Check Analytics Consent")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.indigo)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: getConsentSummary) {
                                    Text("Get Consent Summary")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.teal)
                                        .cornerRadius(8)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: enableDebugMode) {
                                    Text("Enable Debug Mode")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.brown)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: resetConsent) {
                                    Text("Reset Consent")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Ad Testing Section
                        VStack(spacing: 12) {
                            Text("Ad Testing (requires consent and placementId)")
                                .font(.headline)
                                .padding(.top)
                            
                            Button(action: showImageAdIfConsent) {
                                Text("Show Image Ad (if consent)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: showVideoAdIfConsent) {
                                Text("Show Video Ad (if consent)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: showNativeAdIfConsent) {
                                Text("Show Native Ad (if consent)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Ad Display Area
                        if let adView = currentAdView {
                            VStack {
                                Text("Ad Display")
                                    .font(.headline)
                                    .padding(.top)
                                
                                adView
                                    .frame(minHeight: 200, maxHeight: 400)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Cleanup Button
                        Button(action: cleanupSDK) {
                            Text("Cleanup SDK")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Consent Test")
            .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showPlacementIdAlert) {
            Button("OK") { }
        } message: {
            Text("Placement ID is required. Please enter a valid placement ID.")
        }
    }
    
    private func initializeSDK() {
        do {
            let config = SDKConfig.Builder()
                .enableLogging(true)
                .enableDebugMode(true)
                .defaultAdTimeout(30000)
                .defaultAdPosition(AdPosition.unknown)
                .build()
            
            BidscubeSDK.initialize(config: config)
            
            sdkStatus = "SDK Status: Initializing..."
            
            // Simulate initialization check
            DispatchQueue.global().async {
                while !BidscubeSDK.isInitialized() {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                DispatchQueue.main.async {
                    sdkStatus = "SDK Status: Initialized"
                    isSDKInitialized = true
                    updateConsentStatus()
                }
            }
        } catch {
            sdkStatus = "SDK Status: Initialization Failed"
        }
    }
    
    private func requestConsentInfoUpdate() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        showToast("Requesting consent info update...")
        
        BidscubeSDK.requestConsentInfoUpdate(callback: delegate)
    }
    
    private func showConsentForm() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        showToast("Showing consent form...")
        
        BidscubeSDK.showConsentForm(delegate)
    }
    
    private func checkConsentRequired() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        let isRequired = BidscubeSDK.isConsentRequired()
        let message = "Consent required: \(isRequired)"
        showToast(message)
    }
    
    private func checkAdsConsent() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        let hasConsent = BidscubeSDK.hasAdsConsent()
        let message = "Ads consent: \(hasConsent)"
        showToast(message)
    }
    
    private func checkAnalyticsConsent() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        let hasConsent = BidscubeSDK.hasAnalyticsConsent()
        let message = "Analytics consent: \(hasConsent)"
        showToast(message)
    }
    
    private func getConsentSummary() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        let summary = BidscubeSDK.getConsentStatusSummary()
        let shortSummary = summary.count > 100 ? String(summary.prefix(100)) + "..." : summary
        showToast("Consent Summary (see logs): \(shortSummary)")
    }
    
    private func enableDebugMode() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        BidscubeSDK.enableConsentDebugMode("test_device_123")
        showToast("Debug mode enabled for test device")
    }
    
    private func resetConsent() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        BidscubeSDK.resetConsent()
        showToast("Consent information reset")
        updateConsentStatus()
    }
    
    private func showImageAdIfConsent() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        guard BidscubeSDK.hasAdsConsent() else {
            showToast("No ads consent. Request consent first.")
            return
        }
        
        showToast("Showing image ad...")
        let adView = BidscubeSDK.getImageAdView("20212", delegate)
        DispatchQueue.main.async {
            self.currentAdView = AnyView(UIViewRepresentableWrapper(view: adView))
        }
    }
    
    private func showVideoAdIfConsent() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        guard BidscubeSDK.hasAdsConsent() else {
            showToast("No ads consent. Request consent first.")
            return
        }
        
        guard !placementId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showPlacementIdAlert = true
            return
        }
        
        let trimmedPlacementId = placementId.trimmingCharacters(in: .whitespacesAndNewlines)
        showToast("Showing video ad...")
        let adView = BidscubeSDK.getVideoAdView(trimmedPlacementId, delegate)
        DispatchQueue.main.async {
            self.currentAdView = AnyView(UIViewRepresentableWrapper(view: adView))
        }
    }
    
    private func showNativeAdIfConsent() {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            return
        }
        
        guard BidscubeSDK.hasAdsConsent() else {
            showToast("No ads consent. Request consent first.")
            return
        }
        
        guard !placementId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showPlacementIdAlert = true
            return
        }
        
        let trimmedPlacementId = placementId.trimmingCharacters(in: .whitespacesAndNewlines)
        showToast("Showing native ad...")
        let adView = BidscubeSDK.getNativeAdView(trimmedPlacementId, delegate)
        DispatchQueue.main.async {
            self.currentAdView = AnyView(UIViewRepresentableWrapper(view: adView))
        }
    }
    
    private func updateConsentStatus() {
        guard BidscubeSDK.isInitialized() else {
            return
        }
        
        var status = "SDK Status: Initialized\n"
        status += "Consent Required: \(BidscubeSDK.isConsentRequired())\n"
        status += "Ads Consent: \(BidscubeSDK.hasAdsConsent())\n"
        status += "Analytics Consent: \(BidscubeSDK.hasAnalyticsConsent())"
        
        sdkStatus = status
    }
    
    private func cleanupSDK() {
        if BidscubeSDK.isInitialized() {
            BidscubeSDK.cleanup()
            sdkStatus = "SDK Status: Cleaned Up"
            isSDKInitialized = false
            showToast("SDK cleaned up")
        } else {
            showToast("SDK not initialized")
        }
    }
    
    private func showToast(_ message: String) {
        // Simple toast implementation - in a real app you might want to use a proper toast library
        print("Toast: \(message)")
    }
}

#Preview {
    ConsentTestView()
}
