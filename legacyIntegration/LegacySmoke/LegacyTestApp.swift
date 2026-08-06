import SwiftUI

@main
struct LegacyTestApp: App {
    @StateObject private var maxCoordinator = MAXAdCoordinator()
    @StateObject private var directCoordinator = LegacyDirectSDKCoordinator()

    var body: some Scene {
        WindowGroup {
            LegacyMAXTestView()
                .environmentObject(maxCoordinator)
                .environmentObject(directCoordinator)
        }
    }
}
