import Foundation
import FirebaseFirestore

final class ParkingLotRepository {
    private lazy var collection = Firestore.firestore().collection("parking_lots")

    func fetchParkingLots() async throws -> [ParkingLot] {
        let snapshot = try await collection.order(by: "name").getDocumentsAsync()
        return try snapshot.documents.compactMap { try $0.data(as: ParkingLot.self) }
    }

    func fetchParkingLots(ids: [String]) async throws -> [ParkingLot] {
        guard !ids.isEmpty else { return [] }
        let snapshot = try await collection
            .whereField(FieldPath.documentID(), in: Array(ids.prefix(10)))
            .getDocumentsAsync()
        return try snapshot.documents.compactMap { try $0.data(as: ParkingLot.self) }
    }

    func saveParkingLot(_ lot: ParkingLot) async throws {
        let document = collection.document(lot.id ?? UUID().uuidString)
        try await document.setDataAsync(from: lot, merge: true)
    }

    func deleteParkingLot(id: String) async throws {
        try await collection.document(id).deleteAsync()
    }
}
