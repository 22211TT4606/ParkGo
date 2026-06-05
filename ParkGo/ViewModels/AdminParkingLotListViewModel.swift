import Foundation

@MainActor
final class AdminParkingLotListViewModel: ObservableObject {
    @Published var parkingLots: [ParkingLot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let parkingLotRepository: ParkingLotRepository

    init(parkingLotRepository: ParkingLotRepository) {
        self.parkingLotRepository = parkingLotRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            parkingLots = try await parkingLotRepository.fetchParkingLots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(lot: ParkingLot) async {
        do {
            var mutableLot = lot
            if mutableLot.id == nil {
                mutableLot.id = UUID().uuidString
            }
            try await parkingLotRepository.saveParkingLot(mutableLot)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        do {
            try await parkingLotRepository.deleteParkingLot(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
