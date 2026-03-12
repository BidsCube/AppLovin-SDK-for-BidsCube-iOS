import SwiftUI
import bidscubeSdk

struct SDKTestView: View {
    @State private var sdkStatus = "SDK Status: Not Initialized"
    @State private var placementId: String? = nil
    @State private var currentAdPosition = "Current Ad Position: Not Set"
    @State private var isSDKInitialized = false
    @State private var showPlacementIdAlert = false
    @State private var currentAdView: AnyView?
    @State private var selectedPosition: AdPosition = .unknown
    @State private var useManualPosition = false
    @State private var lastDisplayedAdType: AdType?
    @State private var bannerCornerRadius: Double = 0.0
    
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
                    
                    if isSDKInitialized {
                        
                    // Placement ID Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Placement ID Input:")
                            .font(.headline)
                        
                        TextField("Enter placement ID:", text: Binding<String>(
                            get: { placementId ?? "" },
                            set: { placementId = $0.isEmpty ? nil : $0 }
                        ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    // Current Ad Position
                    Text(currentAdPosition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Active Banner Count
                        Text("Active Banners: \(BidscubeSDK.getActiveBannerCount())")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical)
                   
                        // Ad Type Buttons
                        VStack(spacing: 12) {
                            Text("Ad Types")
                                .font(.headline)
                                .padding(.top)
                            
                            Button(action: { showAd(.image) }) {
                                Text("Banner/Image Ads")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { showAd(.video) }) {
                                Text("Video Ads")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { showAd(.native) }) {
                                Text("Native Ads")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange)
                                    .cornerRadius(12)
                            }

                        }
                        
                        // Logging Control
                        VStack(spacing: 12) {
                            Text("Logging Control")
                                .font(.headline)
                                .padding(.top)
                            
                            HStack(spacing: 12) {
                                Button(action: { enableLogging(true) }) {
                                    Text("Enable Logging")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: { enableLogging(false) }) {
                                    Text("Disable Logging")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Button(action: testLogging) {
                                Text("Test Logging")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Cleanup Button
                        // Cleanup SDK Button
                        Button(action: cleanupSDK) {
                            Text("Cleanup SDK")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .disabled(!isSDKInitialized)
                        
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
                    
                    // Position Selection (at the bottom) - FOR TESTING ONLY
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ad Position Selection (Testing Only):")
                            .font(.headline)
                            .padding(.top)
                        
                        Toggle("Override Ad Position for Testing", isOn: $useManualPosition)
                            .font(.subheadline)
                            .onChange(of: useManualPosition) { _ in
                                if lastDisplayedAdType != nil {
                                    refreshCurrentAdWithNewPosition()
                                }
                            }
                        
                        if useManualPosition {
                            Picker("Select Position", selection: $selectedPosition) {
                                ForEach([AdPosition.unknown, .aboveTheFold, .dependOnScreenSize, .belowTheFold, .header, .footer, .sidebar, .fullScreen], id: \.self) { position in
                                    Text("\(position.rawValue) - \(displayName(for: position))")
                                        .tag(position)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onChange(of: selectedPosition) { _ in
                                if useManualPosition && lastDisplayedAdType != nil {
                                    refreshCurrentAdWithNewPosition()
                                }
                            }
                        } else {
                            Text("Position will be determined from server response")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                }
                .padding()
            }
            .navigationTitle("SDK Test")
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
                .defaultAdPosition(AdPosition.unknown) // "UNKNOWN"
                .build()
            
            BidscubeSDK.initialize(config: config)
            SDKLogger.d("SDKTestView", "Bidscube SDK initialized successfully")
            
            sdkStatus = "SDK Status: Initializing..."
            
            // Simulate initialization check
            DispatchQueue.global().async {
                while !BidscubeSDK.isInitialized() {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                DispatchQueue.main.async {
                    sdkStatus = "SDK Status: Initialized"
                    isSDKInitialized = true
                    SDKLogger.d("SDKTestView", "SDK initialization completed")
                }
            }
        } catch {
            sdkStatus = "SDK Status: Initialization Failed"
            SDKLogger.e("SDKTestView", "Failed to initialize SDK: \(error.localizedDescription)")
        }
    }
    
    private func cleanupSDK() {
        SDKLogger.d("SDKTestView", "Cleaning up SDK and removing all banners")
        
        // Remove all active banners
        BidscubeSDK.removeAllBanners()
        
        // Cleanup SDK
        BidscubeSDK.cleanup()
        
        // Update UI state
        sdkStatus = "SDK Status: Cleaned Up"
        isSDKInitialized = false
        currentAdView = nil
        lastDisplayedAdType = nil
        currentAdPosition = "Current Ad Position: Not Set"
        
        showToast("SDK cleaned up. All banners removed.")
        SDKLogger.d("SDKTestView", "SDK cleanup completed")
    }
    
    private func showAd(_ adType: AdType) {
        guard BidscubeSDK.isInitialized() else {
            showToast("SDK not initialized")
            SDKLogger.w("SDKTestView", "SDK not initialized when trying to show ad")
            return
        }
        // Determine correct placementId per button if TextField is empty
        let trimmedPlacementId = (placementId?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
        let effectivePlacementId: String
        switch adType {
        case .image:
            effectivePlacementId = trimmedPlacementId ?? "20212"
        case .video:
            effectivePlacementId = trimmedPlacementId ?? "20213"
        case .native:
            effectivePlacementId = trimmedPlacementId ?? "20214"
        }
        // Remove old empty placement check
        // PlacementID Alert not needed since defaults provided
        
        // Handle manual position override
        if useManualPosition {
            BidscubeSDK.setAdPosition(selectedPosition)
            SDKLogger.d("SDKTestView", "Showing \(adType) ad with placement ID: \(effectivePlacementId) and manual position: \(selectedPosition.rawValue) - \(displayName(for: selectedPosition))")
        } else {
            BidscubeSDK.setAdPosition(.unknown)
            SDKLogger.d("SDKTestView", "Showing \(adType) ad with placement ID: \(effectivePlacementId) - using server response position")
        }
        
        do {
            // Check if manual position override is set to full screen
            let shouldPresentFullScreen = selectedPosition == .fullScreen
            
            if shouldPresentFullScreen {
                // Present full screen ad
                SDKLogger.d("SDKTestView", "Presenting \(adType) ad full screen (manual override)")
                presentFullScreenAd(adType, placementId: effectivePlacementId)
            } else if selectedPosition == .header || selectedPosition == .footer || selectedPosition == .sidebar {
                // Show banner ad for header, footer, or sidebar positions
                SDKLogger.d("SDKTestView", "Showing \(adType) banner ad at position: \(selectedPosition.rawValue) - \(displayName(for: selectedPosition))")
                showBannerAd(adType, placementId: effectivePlacementId, position: selectedPosition)
            } else {
                // Display inline ad
                let adView: UIView
                switch adType {
                case .image:
                    adView = BidscubeSDK.getImageAdView(effectivePlacementId, delegate)
                    
                case .video:
                    adView = BidscubeSDK.getVideoAdView(effectivePlacementId, delegate)
                    
                case .native:
                    adView = BidscubeSDK.getNativeAdView(effectivePlacementId, delegate)
                }
                
                // Display the ad view in SwiftUI
                DispatchQueue.main.async {
                    self.currentAdView = AnyView(UIViewRepresentableWrapper(view: adView))
                    self.lastDisplayedAdType = adType
                }
            }
            
            // Update current ad position and check for server-side full screen
            updatePositionAfterResponse(effectivePlacementId)
            
        } catch {
            let errorMessage = "Failed to show ad: \(error.localizedDescription)"
            showToast(errorMessage)
            SDKLogger.e("SDKTestView", errorMessage)
        }
    }
    
    private func refreshCurrentAdWithNewPosition() {
        guard let adType = lastDisplayedAdType else { return }
        SDKLogger.d("SDKTestView", "Refreshing current ad with new position")
        
        // Clear the current ad view first to avoid view controller hierarchy issues
        DispatchQueue.main.async {
            self.currentAdView = nil
        }
        
        // Add a longer delay to ensure the view hierarchy is completely stable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.showAd(adType)
        }
    }
    
    private func updatePositionAfterResponse(_ placementId: String) {
        // If manual override is enabled, show the selected position immediately
        if useManualPosition {
            DispatchQueue.main.async {
                self.currentAdPosition = "Current Ad Position: \(self.selectedPosition.rawValue) - \(self.displayName(for: self.selectedPosition)) (Manual Override)"
            }
            SDKLogger.d("SDKTestView", "Using manual position override: \(selectedPosition.rawValue) - \(displayName(for: selectedPosition))")
            return
        }
        
        // Otherwise, poll for server response position
        SDKLogger.d("SDKTestView", "Starting position polling for placement: \(placementId)")
        
        DispatchQueue.global().async {
            var attempts = 0
            let maxAttempts = 20
            
            while attempts < maxAttempts {
                do {
                    let responsePosition = BidscubeSDK.getResponseAdPosition()
                    
                    if responsePosition != .unknown {
                        let positionMessage = "Ad position updated from response: \(responsePosition.rawValue) - \(displayName(for: responsePosition))"
                        SDKLogger.d("SDKTestView", positionMessage)
                        
                        DispatchQueue.main.async {
                            self.currentAdPosition = "Current Ad Position: \(responsePosition.rawValue) - \(self.displayName(for: responsePosition))"
                            
                            // Check if server response indicates full screen and we have an inline ad
                            if responsePosition == .fullScreen && self.currentAdView != nil {
                                SDKLogger.d("SDKTestView", "Server response indicates full screen - transitioning to full screen")
                                // Clear inline ad and present full screen
                                self.currentAdView = nil
                                if let adType = self.lastDisplayedAdType {
                                    self.presentFullScreenAd(adType, placementId: placementId)
                                }
                            }
                            // Check if server response indicates banner position and we have an inline ad
                            else if (responsePosition == .header || responsePosition == .footer || responsePosition == .sidebar) && self.currentAdView != nil {
                                SDKLogger.d("SDKTestView", "Server response indicates banner position - transitioning to banner")
                                // Clear inline ad and present banner
                                self.currentAdView = nil
                                if let adType = self.lastDisplayedAdType {
                                    self.showBannerAd(adType, placementId: placementId, position: responsePosition)
                                }
                            }
                        }
                        return
                    }
                    
                    Thread.sleep(forTimeInterval: 0.1)
                    attempts += 1
                } catch {
                    SDKLogger.e("SDKTestView", "Error while polling for position: \(error.localizedDescription)")
                    break
                }
            }
            
            SDKLogger.w("SDKTestView", "Position polling timed out after \(maxAttempts) attempts")
            DispatchQueue.main.async {
                self.currentAdPosition = "Current Ad Position: 0 - UNKNOWN (timeout)"
            }
        }
    }

    
    private func enableLogging(_ enabled: Bool) {
        SDKLogger.setLoggingEnabled(enabled)
        let message = "Logging \(enabled ? "enabled" : "disabled")"
        showToast(message)
        SDKLogger.d("SDKTestView", "Logging control: \(message)")
    }
    
    private func testLogging() {
        SDKLogger.d("SDKTestView", "=== LOGGING TEST ===")
        SDKLogger.i("SDKTestView", "This is an INFO message")
        SDKLogger.w("SDKTestView", "This is a WARNING message")
        SDKLogger.e("SDKTestView", "This is an ERROR message")
        SDKLogger.v("SDKTestView", "This is a VERBOSE message")
        
        SDKLogger.d("SDKTestView", "=== SDK LOGGER TEST ===")
        SDKLogger.i("SDKTestView", "This is an SDK INFO message")
        SDKLogger.w("SDKTestView", "This is an SDK WARNING message")
        SDKLogger.e("SDKTestView", "This is an SDK ERROR message")
        SDKLogger.v("SDKTestView", "This is an SDK VERBOSE message")
        
        let message = "Logging test completed. Check logs to see which messages appear."
        showToast(message)
        SDKLogger.d("SDKTestView", "Logging test completed - check if SDKLogger messages are filtered")
    }
    
    private func displayName(for position: bidscubeSdk.AdPosition) -> String {
        switch position {
        case .unknown:
            return "UNKNOWN"
        case .aboveTheFold:
            return "ABOVE_THE_FOLD"
        case .dependOnScreenSize:
            return "DEPEND_ON_SCREEN_SIZE"
        case .belowTheFold:
            return "BELOW_THE_FOLD"
        case .header:
            return "HEADER"
        case .footer:
            return "FOOTER"
        case .sidebar:
            return "SIDEBAR"
        case .fullScreen:
            return "FULL_SCREEN"
        }
    }
    
    private func presentFullScreenAd(_ adType: AdType, placementId: String) {
        // Get the current view controller from the window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            SDKLogger.e("SDKTestView", "Could not find root view controller for full screen presentation")
            showToast("Could not present full screen ad")
            return
        }
        
        // Find the topmost view controller
        let topViewController = findTopViewController(from: rootViewController)
        
        // Present the ad using the SDK's full screen method
        BidscubeSDK.presentAd(placementId, adType, from: topViewController, delegate)
        
        // Clear the current ad view since we're showing full screen
        DispatchQueue.main.async {
            self.currentAdView = nil
            self.lastDisplayedAdType = adType
        }
    }
    
    private func showBannerAd(_ adType: AdType, placementId: String, position: AdPosition) {
        // Get the current view controller from the window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            SDKLogger.e("SDKTestView", "Could not find root view controller for banner presentation")
            showToast("Could not present banner ad")
            return
        }
        
        // Find the topmost view controller
        let topViewController = findTopViewController(from: rootViewController)
        
        // Show banner ad based on position with custom corner radius
        switch position {
        case .header:
            BidscubeSDK.showBannerWithCornerRadius(placementId, position: .header, cornerRadius: CGFloat(bannerCornerRadius), in: topViewController, callback: delegate)
        case .footer:
            BidscubeSDK.showBannerWithCornerRadius(placementId, position: .footer, cornerRadius: CGFloat(bannerCornerRadius), in: topViewController, callback: delegate)
        case .sidebar:
            BidscubeSDK.showBannerWithCornerRadius(placementId, position: .sidebar, cornerRadius: CGFloat(bannerCornerRadius), in: topViewController, callback: delegate)
        default:
            SDKLogger.w("SDKTestView", "Invalid position for banner ad: \(position)")
            showToast("Invalid position for banner ad")
            return
        }
        
        // Clear the current ad view since we're showing banner
        DispatchQueue.main.async {
            self.currentAdView = nil
            self.lastDisplayedAdType = adType
        }
        
        SDKLogger.d("SDKTestView", "Banner ad shown at position: \(position.rawValue) - \(displayName(for: position))")
    }
    
    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return findTopViewController(from: presentedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return findTopViewController(from: navigationController.visibleViewController ?? navigationController)
        }
        
        if let tabBarController = viewController as? UITabBarController {
            return findTopViewController(from: tabBarController.selectedViewController ?? tabBarController)
        }
        
        return viewController
    }
    
    private func showToast(_ message: String) {
        // Simple toast implementation - in a real app you might want to use a proper toast library
        print("Toast: \(message)")
    }
}

#Preview {
    SDKTestView()
}
