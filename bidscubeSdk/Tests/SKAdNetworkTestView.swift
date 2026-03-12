import SwiftUI
import bidscubeSdk

struct SKAdNetworkTestView: View {
    @State private var skAdNetworkIDs: [String] = []
    @State private var displayText: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("SKAdNetwork Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Test SKAdNetwork ID reading from Info.plist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    Button(action: {
                        loadSKAdNetworkIDs()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Load SKAdNetwork IDs")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: {
                        displayInConsole()
                    }) {
                        HStack {
                            Image(systemName: "terminal")
                            Text("Display in Console")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(skAdNetworkIDs.isEmpty)
                    
                    Button(action: {
                        loadDebugInfo()
                    }) {
                        HStack {
                            Image(systemName: "ladybug")
                            Text("Debug Info.plist")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                if !skAdNetworkIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SKAdNetwork IDs (\(skAdNetworkIDs.count) total):")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 5) {
                                ForEach(Array(skAdNetworkIDs.enumerated()), id: \.offset) { index, id in
                                    HStack {
                                        Text("[\(index + 1)]")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 30, alignment: .leading)
                                        
                                        Text(id)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                if !displayText.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Formatted Output:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView {
                            Text(displayText)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("SKAdNetwork Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadSKAdNetworkIDs()
        }
    }
    
    private func loadSKAdNetworkIDs() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let ids = BidscubeSDK.getSKAdNetworkIDs()
            let formattedText = BidscubeSDK.getSKAdNetworkIDsAsString()
            
            DispatchQueue.main.async {
                self.skAdNetworkIDs = ids
                self.displayText = formattedText
                self.isLoading = false
            }
        }
    }
    
    private func displayInConsole() {
        BidscubeSDK.displaySKAdNetworkIDsInConsole()
    }
    
    private func loadDebugInfo() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let debugInfo = BidscubeSDK.debugInfoPlistStructure()
            
            DispatchQueue.main.async {
                self.displayText = debugInfo
                self.isLoading = false
            }
        }
    }
}

#Preview {
    SKAdNetworkTestView()
}
