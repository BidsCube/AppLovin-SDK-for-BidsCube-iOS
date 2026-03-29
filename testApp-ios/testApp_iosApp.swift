//
//  testApp_iosApp.swift
//  testApp-ios
//
//  Created by Vladyslav Humennyi on 09/09/2025.
//

import SwiftUI
import BidscubeSDK

@main
struct testApp_iosApp: App {
    init() {
            let processInfo = ProcessInfo.processInfo
            let customAuthority = processInfo.environment["bidcube.testSspAuthority"]
                ?? processInfo.environment["BIDSCUBE_TEST_SSP_AUTHORITY"]

            let builder = SDKConfig.Builder()
                .enableLogging(true)
                .enableDebugMode(true)
                .defaultAdTimeout(10_000)
                .defaultAdPosition(.unknown)
                .enableSKAdNetwork(true)
                .skAdNetworkId("com.bidscube.skadnetwork")
                .skAdNetworkConversionValue(0)

            if let customAuthority, !customAuthority.isEmpty {
                _ = builder.adRequestAuthority(customAuthority)
            }

            let config = builder.build()
            BidscubeSDK.initialize(config: config)
        }

        var body: some Scene {
            WindowGroup { ContentView() }
        }
}
