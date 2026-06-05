import Foundation
import FirebaseAuth

@MainActor
final class AppStateViewModel: ObservableObject {
    enum SessionState {
        case checking
        case signedOut
        case signedIn(UserProfile)
    }

    @Published private(set) var sessionState: SessionState = .checking
    @Published var errorMessage: String?

    private let authService: AuthService
    private let userRepository: UserRepository
    private var authHandle: AuthStateDidChangeListenerHandle?

    init(authService: AuthService, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
        observeAuth()
    }

    deinit {
        if let authHandle {
            authService.removeListener(authHandle)
        }
    }

    func refreshProfile() async {
        guard let userID = authService.currentUserID else {
            sessionState = .signedOut
            return
        }
        await loadProfile(userID: userID)
    }

    func signOut() {
        do {
            try authService.signOut()
            sessionState = .signedOut
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func observeAuth() {
        guard authService.isAvailable else {
            sessionState = .signedOut
            errorMessage = "Firebase chưa được cấu hình. Kiểm tra GoogleService-Info.plist và chạy lại xcodegen generate."
            return
        }
        authHandle = authService.observeAuthState { [weak self] user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    await self.loadProfile(userID: user.uid)
                } else {
                    self.sessionState = .signedOut
                }
            }
        }
    }

    private func loadProfile(userID: String) async {
        sessionState = .checking
        do {
            if let profile = try await userRepository.fetchUser(userID: userID) {
                sessionState = .signedIn(profile)
            } else {
                sessionState = .signedOut
                errorMessage = "User profile not found in Firestore."
            }
        } catch {
            sessionState = .signedOut
            errorMessage = error.localizedDescription
        }
    }
}
