import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var favorites: [ParkingLot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let favoriteRepository: FavoriteRepository
    private let parkingLotRepository: ParkingLotRepository

    init(favoriteRepository: FavoriteRepository, parkingLotRepository: ParkingLotRepository) {
        self.favoriteRepository = favoriteRepository
        self.parkingLotRepository = parkingLotRepository
    }

    func load(userID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let favoriteDocs = try await favoriteRepository.fetchFavorites(userID: userID)
            let ids = favoriteDocs.map(\.parkingLotID)
            favorites = try await parkingLotRepository.fetchParkingLots(ids: ids)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(userID: String, parkingLotID: String) async {
        do {
            try await favoriteRepository.toggleFavorite(userID: userID, parkingLotID: parkingLotID)
            await load(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
