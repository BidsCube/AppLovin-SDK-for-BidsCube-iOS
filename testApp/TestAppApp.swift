import SwiftUI

@main
struct TestAppApp: App {
    @StateObject private var coordinator = MAXAdCoordinator()

    var body: some Scene {
        WindowGroup {
            MAXTestView()
                .environmentObject(coordinator)
        }
    }
}
