import Foundation
import CoreLocation

@MainActor
final class UserHomeViewModel: ObservableObject {
    @Published var parkingLots: [ParkingLot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let parkingLotRepository: ParkingLotRepository

    init(parkingLotRepository: ParkingLotRepository) {
        self.parkingLotRepository = parkingLotRepository
    }

    func loadLots(userLocation: CLLocationCoordinate2D?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let lots = try await parkingLotRepository.fetchParkingLots()
            if let userLocation {
                parkingLots = lots.sorted {
                    $0.coordinate.distance(to: userLocation) < $1.coordinate.distance(to: userLocation)
                }
            } else {
                parkingLots = lots
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

