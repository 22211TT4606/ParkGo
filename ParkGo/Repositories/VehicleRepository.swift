import Foundation
import FirebaseFirestore

final class VehicleRepository {
    private lazy var collection = Firestore.firestore().collection("vehicles")

    func fetchVehicles(userID: String) async throws -> [Vehicle] {
        let snapshot = try await collection
            .whereField("userID", isEqualTo: userID)
            .getDocumentsAsync()
        return try snapshot.documents.compactMap { try $0.data(as: Vehicle.self) }
    }

    func saveVehicle(_ vehicle: Vehicle) async throws {
        let document = collection.document(vehicle.id ?? UUID().uuidString)
        try await document.setDataAsync(from: vehicle, merge: true)
    }

    func deleteVehicle(id: String) async throws {
        try await collection.document(id).deleteAsync()
    }
}
