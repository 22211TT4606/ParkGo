import Foundation

@MainActor
final class AppDependencies {
    let authService: AuthService
    let userRepository: UserRepository
    let parkingLotRepository: ParkingLotRepository
    let reviewRepository: ReviewRepository
    let favoriteRepository: FavoriteRepository
    let vehicleRepository: VehicleRepository
    let checkInRepository: CheckInRepository
    let searchHistoryRepository: SearchHistoryRepository
    let parkingHistoryRepository: ParkingHistoryRepository
    let locationService: LocationService
    let mapService: MapService
    let seedDataService: SeedDataService
    let navigationCoordinator: NavigationCoordinator

    init() {
        authService = AuthService()
        userRepository = UserRepository()
        parkingLotRepository = ParkingLotRepository()
        reviewRepository = ReviewRepository()
        favoriteRepository = FavoriteRepository()
        vehicleRepository = VehicleRepository()
        checkInRepository = CheckInRepository()
        searchHistoryRepository = SearchHistoryRepository()
        parkingHistoryRepository = ParkingHistoryRepository()
        locationService = LocationService()
        mapService = MapService()
        navigationCoordinator = NavigationCoordinator()
        seedDataService = SeedDataService(
            authService: authService,
            userRepository: userRepository,
            parkingLotRepository: parkingLotRepository,
            reviewRepository: reviewRepository,
            favoriteRepository: favoriteRepository,
            vehicleRepository: vehicleRepository,
            checkInRepository: checkInRepository,
            searchHistoryRepository: searchHistoryRepository,
            parkingHistoryRepository: parkingHistoryRepository
        )
    }
}
