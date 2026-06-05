import SwiftUI

@main
struct ParkGoApp: App {
    private let dependencies: AppDependencies
    @StateObject private var appState: AppStateViewModel

    init() {
        FirebaseBootstrapper.configure()
        let dependencies = AppDependencies()
        self.dependencies = dependencies
        _appState = StateObject(
            wrappedValue: AppStateViewModel(
                authService: dependencies.authService,
                userRepository: dependencies.userRepository
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environmentObject(appState)
                .preferredColorScheme(nil)
        }
    }
}

