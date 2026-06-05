import Foundation

@MainActor
final class AdminDashboardViewModel: ObservableObject {
    @Published var stats = DashboardStats()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let parkingLotRepository: ParkingLotRepository
    private let userRepository: UserRepository
    private let checkInRepository: CheckInRepository
    private let reviewRepository: ReviewRepository

    init(
        parkingLotRepository: ParkingLotRepository,
        userRepository: UserRepository,
        checkInRepository: CheckInRepository,
        reviewRepository: ReviewRepository
    ) {
        self.parkingLotRepository = parkingLotRepository
        self.userRepository = userRepository
        self.checkInRepository = checkInRepository
        self.reviewRepository = reviewRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let lots = try await parkingLotRepository.fetchParkingLots()
            let users = try await userRepository.fetchAllUsers()
            let checkIns = try await checkInRepository.fetchCheckIns()
            let reviews = try await reviewRepository.fetchReviews()

            stats = DashboardStats(
                totalParkingLots: lots.count,
                totalUsers: users.count,
                totalCheckIns: checkIns.count,
                totalReviews: reviews.count,
                availableLots: lots.filter { $0.isAvailable }.count,
                fullLots: lots.filter { !$0.isAvailable }.count
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
