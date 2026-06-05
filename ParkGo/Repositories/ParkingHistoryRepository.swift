import Foundation
import FirebaseFirestore

final class ParkingHistoryRepository {
    private lazy var collection = Firestore.firestore().collection("parking_history")

    func fetchLatestMemory(userID: String) async throws -> ParkingMemory? {
        let snapshot = try await collection
            .whereField("userID", isEqualTo: userID)
            .getDocumentsAsync()
        let items = try snapshot.documents.compactMap { try $0.data(as: ParkingMemory.self) }
        return items.sorted { $0.createdAt > $1.createdAt }.first
    }

    func saveMemory(_ memory: ParkingMemory) async throws {
        try await collection.document(memory.id ?? UUID().uuidString).setDataAsync(from: memory, merge: true)
    }
}
