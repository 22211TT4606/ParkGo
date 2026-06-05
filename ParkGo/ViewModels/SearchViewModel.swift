import Foundation
import CoreLocation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var filters = ParkingSearchFilters()
    @Published var results: [ParkingLot] = []
    @Published var history: [SearchHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let parkingLotRepository: ParkingLotRepository
    private let searchHistoryRepository: SearchHistoryRepository
    private var allLots: [ParkingLot] = []

    init(parkingLotRepository: ParkingLotRepository, searchHistoryRepository: SearchHistoryRepository) {
        self.parkingLotRepository = parkingLotRepository
        self.searchHistoryRepository = searchHistoryRepository
    }

    func load(userID: String, userLocation: CLLocationCoordinate2D?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            allLots = try await parkingLotRepository.fetchParkingLots()
            history = try await searchHistoryRepository.fetchHistory(userID: userID)
            applyFilters(userLocation: userLocation)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyFilters(userLocation: CLLocationCoordinate2D?) {
        let isIdle = query.isEmpty && !filters.onlyEVCharging && !filters.onlyOvernight
            && !filters.underTwenty && !filters.onlyAvailable

        var filtered = allLots.filter { lot in
            let textMatch = query.isEmpty ||
                lot.name.localizedCaseInsensitiveContains(query) ||
                lot.address.localizedCaseInsensitiveContains(query)
            let evMatch = !filters.onlyEVCharging || lot.hasEVCharging
            let overnightMatch = !filters.onlyOvernight || lot.isOvernight
            let priceMatch = !filters.underTwenty || lot.hourlyRate < 20
            let availabilityMatch = !filters.onlyAvailable || lot.availableSpots > 0
            return textMatch && evMatch && overnightMatch && priceMatch && availabilityMatch
        }

        if let userLocation {
            filtered.sort { $0.coordinate.distance(to: userLocation) < $1.coordinate.distance(to: userLocation) }
        } else {
            filtered.sort { $0.name < $1.name }
        }

        results = isIdle ? Array(filtered.prefix(10)) : filtered
    }

    func saveSearch(userID: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let historyItem = SearchHistory(userID: userID, keyword: query, filtersSummary: filters.summary, createdAt: .now)
        do {
            try await searchHistoryRepository.saveHistory(historyItem)
            history = try await searchHistoryRepository.fetchHistory(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

