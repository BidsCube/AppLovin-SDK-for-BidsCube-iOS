//
//  testApp_iosApp.swift
//  testApp-ios
//
//  Created by Vladyslav Humennyi on 09/09/2025.
//

import SwiftUI
import bidscubeSdk

@main
struct testApp_iosApp: App {
    init() {
            let config = SDKConfig.Builder()
                .enableLogging(true)
                .enableDebugMode(true)
                .defaultAdTimeout(10_000)
                .defaultAdPosition(.unknown)
                .enableSKAdNetwork(true)
                .skAdNetworkId("com.bidscube.skadnetwork")
                .skAdNetworkConversionValue(0)
                .build()
            BidscubeSDK.initialize(config: config)
        }

        var body: some Scene {
            WindowGroup { ContentView() }
        }
}
