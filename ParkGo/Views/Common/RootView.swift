import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppStateViewModel
    let dependencies: AppDependencies

    var body: some View {
        Group {
            switch appState.sessionState {
            case .checking:
                LoadingStateView(title: "Đang kiểm tra đăng nhập...", subtitle: "ParkGo đang đồng bộ tài khoản và quyền truy cập.")
            case .signedOut:
                AuthView(
                    viewModel: AuthViewModel(
                        authService: dependencies.authService,
                        userRepository: dependencies.userRepository,
                        seedDataService: dependencies.seedDataService
                    )
                )
            case .signedIn(let profile):
                if profile.role == .admin {
                    AdminShellView(profile: profile, dependencies: dependencies)
                } else {
                    UserShellView(profile: profile, dependencies: dependencies)
                }
            }
        }
        .alert("Thông báo", isPresented: Binding<Bool>(
            get: { appState.errorMessage != nil },
            set: { _ in appState.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}

