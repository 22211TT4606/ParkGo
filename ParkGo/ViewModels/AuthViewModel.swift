import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Mode: String, CaseIterable {
        case signIn = "Đăng nhập"
        case signUp = "Đăng ký"
    }

    @Published var mode: Mode = .signIn
    @Published var fullName = ""
    @Published var phoneNumber = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let authService: AuthService
    private let userRepository: UserRepository
    private let seedDataService: SeedDataService

    init(authService: AuthService, userRepository: UserRepository, seedDataService: SeedDataService) {
        self.authService = authService
        self.userRepository = userRepository
        self.seedDataService = seedDataService
    }

    func submit() async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            switch mode {
            case .signIn:
                _ = try await authService.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            case .signUp:
                guard password == confirmPassword else {
                    throw ValidationError(message: "Mật khẩu xác nhận chưa khớp.")
                }
                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                let userID = try await authService.register(email: cleanEmail, password: password)
                let profile = UserProfile(
                    id: userID,
                    fullName: fullName,
                    email: cleanEmail,
                    phoneNumber: phoneNumber,
                    role: .user,
                    createdAt: .now,
                    updatedAt: .now
                )
                try await userRepository.saveUser(profile, userID: userID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func seedDemoData() async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await seedDataService.seedAllData()
            infoMessage = "Seed demo data thành công. Bạn có thể đăng nhập ngay."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ValidationError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

