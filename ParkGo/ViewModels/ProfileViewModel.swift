import Foundation
import CoreLocation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var vehicles: [Vehicle] = []
    @Published var parkingMemory: ParkingMemory?
    @Published var recommendedLots: [ParkingLot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let authService: AuthService
    private let userRepository: UserRepository
    private let vehicleRepository: VehicleRepository
    private let parkingHistoryRepository: ParkingHistoryRepository
    private let parkingLotRepository: ParkingLotRepository

    init(
        profile: UserProfile,
        authService: AuthService,
        userRepository: UserRepository,
        vehicleRepository: VehicleRepository,
        parkingHistoryRepository: ParkingHistoryRepository,
        parkingLotRepository: ParkingLotRepository
    ) {
        self.profile = profile
        self.authService = authService
        self.userRepository = userRepository
        self.vehicleRepository = vehicleRepository
        self.parkingHistoryRepository = parkingHistoryRepository
        self.parkingLotRepository = parkingLotRepository
    }

    func load() async {
        guard let userID = profile.id else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if let refreshed = try await userRepository.fetchUser(userID: userID) {
                profile = refreshed
            }
            vehicles = try await vehicleRepository.fetchVehicles(userID: userID)
            parkingMemory = try await parkingHistoryRepository.fetchLatestMemory(userID: userID)
            let lots = try await parkingLotRepository.fetchParkingLots()
            recommendedLots = vehicles.contains(where: { $0.isElectric }) ? lots.filter({ $0.hasEVCharging }) : lots
            recommendedLots = Array(recommendedLots.prefix(3))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile() async {
        guard let userID = profile.id else { return }
        do {
            profile.updatedAt = .now
            try await userRepository.saveUser(profile, userID: userID)
            infoMessage = "Cập nhật hồ sơ thành công."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveVehicle(_ vehicle: Vehicle) async {
        do {
            try await vehicleRepository.saveVehicle(vehicle)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteVehicle(id: String) async {
        do {
            try await vehicleRepository.deleteVehicle(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await authService.changePassword(
            email: profile.email,
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        infoMessage = "Đổi mật khẩu thành công."
    }

    func saveParkingMemory(lot: ParkingLot?, currentLocation: CLLocationCoordinate2D?, note: String) async {
        guard let userID = profile.id else { return }
        let fallbackLot = currentLocation.map { coordinate in
            ParkingLot(
                id: nil,
                name: "Current Position",
                address: "Saved from GPS",
                district: "",
                city: "",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                hourlyRate: 0,
                availableSpots: 0,
                totalSpots: 0,
                isOpen: true,
                hasEVCharging: false,
                isOvernight: false,
                imageURLs: [],
                amenities: [],
                createdAt: .now,
                updatedAt: .now
            )
        }

        guard let lot = lot ?? fallbackLot else {
            errorMessage = "Không lấy được vị trí hiện tại. Vui lòng bật GPS và thử lại."
            return
        }

        do {
            let memory = ParkingMemory(
                userID: userID,
                parkingLotID: lot.id,
                parkingLotName: lot.name,
                latitude: lot.latitude,
                longitude: lot.longitude,
                slotNote: note,
                createdAt: .now
            )
            try await parkingHistoryRepository.saveMemory(memory)
            parkingMemory = memory
            infoMessage = "Đã lưu vị trí đỗ xe hiện tại."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
