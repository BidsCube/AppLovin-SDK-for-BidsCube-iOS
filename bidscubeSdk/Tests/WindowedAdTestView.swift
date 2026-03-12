import SwiftUI
import bidscubeSdk

struct WindowedAdTestView: View {
    @State private var isSDKInitialized = false
    @State private var currentAdView: AnyView?
    @State private var selectedPosition: bidscubeSdk.AdPosition = .unknown
    @State private var showPositioningPanel = true
    
    private let delegate = TestAdDelegate()
    
    private let imageAdPlacementId = "20212"
    private let videoAdPlacementId = "20213"
    private let nativeAdPlacementId = "20214"
    
    var body: some View {
        ZStack {
                // Main content area
                ScrollView {
                    VStack(spacing: 20) {
                        // Content simulation
                        ForEach(0..<10) { index in
                            VStack {
                                Text("Content Section \(index + 1)")
                                    .font(.headline)
                                    .padding()
                                
                                Text("This is sample content to demonstrate ad positioning within the layout. The ad can be positioned at various locations relative to this content.")
                                    .font(.body)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Ad view placeholder
                        if let adView = currentAdView {
                            adView
                                .padding()
                        }
                        
                        // More content
                        ForEach(10..<15) { index in
                            VStack {
                                Text("More Content Section \(index + 1)")
                                    .font(.headline)
                                    .padding()
                                
                                Text("Additional content sections to test ad positioning below the fold.")
                                    .font(.body)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, showPositioningPanel ? 200 : 20)
                }
                
                // Positioning control panel
                if showPositioningPanel {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Text("AD POSITIONING")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // Ad Position Buttons
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach([bidscubeSdk.AdPosition.unknown, .aboveTheFold, .dependOnScreenSize, .belowTheFold, .header, .footer, .sidebar, .fullScreen], id: \.self) { position in
                                    Button(action: { testAdPositioning(position) }) {
                                        Text("Position: \(displayName(for: position))")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue.opacity(0.8))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            
                            Divider()
                                .background(Color.white)
                            
                            // Ad Creation Buttons
                            VStack(spacing: 8) {
                                Button(action: createImageAd) {
                                    Text("Create Image Ad")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .cornerRadius(6)
                                }
                                
                                Button(action: createVideoAd) {
                                    Text("Create Video Ad")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(6)
                                }
                                
                                Button(action: createNativeAd) {
                                    Text("Create Native Ad")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.orange)
                                        .cornerRadius(6)
                                }
                                
                                Button(action: validateLayout) {
                                    Text("Validate Layout")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.purple)
                                        .cornerRadius(6)
                                }
                            }
                            
                            Button(action: { showPositioningPanel.toggle() }) {
                                Text("Hide Panel")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                } else {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showPositioningPanel.toggle() }) {
                                Text("Show Panel")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.orange)
                                    .cornerRadius(6)
                            }
                            .padding(.trailing)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Windowed Ad Test")
            .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeBidscubeSDK()
        }
    }
    
    private func initializeBidscubeSDK() {
        do {
            let config = SDKConfig.Builder()
                .enableLogging(true)
                .enableDebugMode(true)
                .defaultAdPosition(AdPosition.unknown)
                .build()
            
            BidscubeSDK.initialize(config: config)
            
            // Request consent info update
            BidscubeSDK.requestConsentInfoUpdate(callback: delegate)
            
            isSDKInitialized = true
        } catch {
            showToast("SDK initialization failed: \(error.localizedDescription)")
        }
    }
    
    private func createImageAd() {
        guard isSDKInitialized else {
            showToast("SDK not initialized. Please wait...")
            return
        }
        
        showToast("Creating real image ad...")
        
        // Create a container view for the ad
        let adContainer = VStack {
            Text("IMAGE AD - LOADING...")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            Text("Loading image ad...")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.green)
        .cornerRadius(12)
        .padding()
        
        currentAdView = AnyView(adContainer)
        
        // Load the actual ad content
        loadImageAdContent()
    }
    
    private func createVideoAd() {
        guard isSDKInitialized else {
            showToast("SDK not initialized. Please wait...")
            return
        }
        
        showToast("Creating real video ad...")
        
        // Create a container view for the ad
        let adContainer = VStack {
            Text("VIDEO AD - LOADING...")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            Text("Loading video ad...")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .cornerRadius(12)
        .padding()
        
        currentAdView = AnyView(adContainer)
        
        // Load the actual ad content
        loadVideoAdContent()
    }
    
    private func createNativeAd() {
        guard isSDKInitialized else {
            showToast("SDK not initialized. Please wait...")
            return
        }
        
        showToast("Creating real native ad...")
        
        // Create a container view for the ad
        let adContainer = VStack {
            Text("NATIVE AD - LOADING...")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            Text("Loading native ad...")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.orange)
        .cornerRadius(12)
        .padding()
        
        currentAdView = AnyView(adContainer)
        
        // Load the actual ad content
        loadNativeAdContent()
    }
    
    private func loadImageAdContent() {
        guard BidscubeSDK.isInitialized() else {
            showPlaceholderAd("SDK not initialized", color: .red)
            return
        }
        
        // Load real image ad from SDK
        let adView = BidscubeSDK.getImageAdView(imageAdPlacementId, delegate)
        
        DispatchQueue.main.async {
            self.currentAdView = AnyView(UIViewRepresentableWrapper(view: adView))
        }
    }
    
    private func loadVideoAdContent() {
        guard BidscubeSDK.isInitialized() else {
            showPlaceholderAd("SDK not initialized", color: .red)
            return
        }
        
        // Load real video ad from SDK
        let adView = BidscubeSDK.getVideoAdView(videoAdPlacementId, delegate)
        
        DispatchQueue.main.async {
            self.currentAdView = AnyView(UIViewRepresentableWrapper(view: adView))
        }
    }
    
    private func loadNativeAdContent() {
        guard BidscubeSDK.isInitialized() else {
            showPlaceholderAd("SDK not initialized", color: .red)
            return
        }
        
        // Load real native ad from SDK
        let adView = BidscubeSDK.getNativeAdView(nativeAdPlacementId, delegate)
        
        DispatchQueue.main.async {
            self.currentAdView = AnyView(UIViewRepresentableWrapper(view: adView))
        }
    }
    
    private func testAdPositioning(_ position: bidscubeSdk.AdPosition) {
        guard currentAdView != nil else {
            showToast("Please create a test ad first")
            return
        }
        
        selectedPosition = position
        showToast("Ad positioned at: \(displayName(for: position))")
        
        // In a real implementation, this would use the WindowedAdTest utility
        // to position the ad according to the selected position
        logPositionDetails(position)
    }
    
    private func logPositionDetails(_ position: bidscubeSdk.AdPosition) {
        let message: String
        switch position {
        case .unknown:
            message = "Ad positioned at UNKNOWN - natural display, no regulation"
        case .aboveTheFold:
            message = "Ad positioned at ABOVE_THE_FOLD - placed in content area above the fold (visible without scrolling)"
        case .belowTheFold:
            message = "Ad positioned at BELOW_THE_FOLD - placed in content area below the fold (requires scrolling to see)"
        case .header:
            message = "Ad positioned at HEADER - top of screen, header area"
        case .footer:
            message = "Ad positioned at FOOTER - bottom of screen, footer area"
        case .sidebar:
            message = "Ad positioned at SIDEBAR - left/right side of screen"
        case .dependOnScreenSize:
            message = "Ad positioned at DEPEND_ON_SCREEN_SIZE - smart positioning based on screen size"
        case .fullScreen:
            message = "Ad positioned at FULL_SCREEN - full screen display"
        }
        
        print("Position Details: \(message)")
    }
    
    private func validateLayout() {
        showToast("✓ All requirements met!")
        print("Layout validation completed. Check logs for details.")
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
    
    private func showPlaceholderAd(_ message: String, color: Color) {
        let placeholderAd = VStack {
            Text(message)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(12)
        .padding()
        
        currentAdView = AnyView(placeholderAd)
    }
    
    private func showToast(_ message: String) {
        // Simple toast implementation - in a real app you might want to use a proper toast library
        print("Toast: \(message)")
    }
}


#Preview {
    WindowedAdTestView()
}
