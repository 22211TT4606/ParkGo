import Foundation
import FirebaseFirestore

final class CheckInRepository {
    private lazy var collection = Firestore.firestore().collection("checkins")

    func fetchCheckIns(userID: String? = nil) async throws -> [CheckIn] {
        let query: Query
        if let userID {
            query = collection.whereField("userID", isEqualTo: userID)
        } else {
            query = collection
        }
        let snapshot = try await query.getDocumentsAsync()
        let items = try snapshot.documents.compactMap { try $0.data(as: CheckIn.self) }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func saveCheckIn(_ checkIn: CheckIn) async throws {
        try await collection.document(checkIn.id ?? UUID().uuidString).setDataAsync(from: checkIn, merge: true)
    }
}
