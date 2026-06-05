import Foundation

@MainActor
final class AdminUsersViewModel: ObservableObject {
    @Published var users: [UserProfile] = []
    @Published var userVehicles: [String: [Vehicle]] = [:]
    @Published var userCheckIns: [String: [CheckIn]] = [:]
    @Published var isLoading = false
    @Published var isCreating = false
    @Published var isUpdating = false
    @Published var errorMessage: String?
    @Published var createError: String?
    @Published var updateError: String?

    private let authService: AuthService
    private let userRepository: UserRepository
    private let vehicleRepository: VehicleRepository
    private let checkInRepository: CheckInRepository

    init(
        authService: AuthService,
        userRepository: UserRepository,
        vehicleRepository: VehicleRepository,
        checkInRepository: CheckInRepository
    ) {
        self.authService = authService
        self.userRepository = userRepository
        self.vehicleRepository = vehicleRepository
        self.checkInRepository = checkInRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            users = try await userRepository.fetchAllUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDetail(for user: UserProfile) async {
        guard let userID = user.id else { return }
        do {
            userVehicles[userID] = try await vehicleRepository.fetchVehicles(userID: userID)
            userCheckIns[userID] = try await checkInRepository.fetchCheckIns(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateUser(_ user: UserProfile) async throws {
        guard let uid = user.id else { return }
        isUpdating = true
        updateError = nil
        defer { isUpdating = false }
        try await userRepository.saveUser(user, userID: uid)
        if let index = users.firstIndex(where: { $0.id == uid }) {
            users[index] = user
        }
    }

    func createUser(fullName: String, email: String, password: String, phoneNumber: String, role: UserRole) async throws {
        isCreating = true
        createError = nil
        defer { isCreating = false }

        let uid = try await authService.adminCreateUser(email: email, password: password)
        let profile = UserProfile(
            fullName: fullName,
            email: email,
            phoneNumber: phoneNumber,
            role: role
        )
        try await userRepository.saveUser(profile, userID: uid)
        await load()
    }
}
