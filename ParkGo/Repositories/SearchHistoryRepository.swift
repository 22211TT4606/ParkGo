import Foundation
import FirebaseFirestore

final class SearchHistoryRepository {
    private lazy var collection = Firestore.firestore().collection("search_history")

    func fetchHistory(userID: String) async throws -> [SearchHistory] {
        let snapshot = try await collection
            .whereField("userID", isEqualTo: userID)
            .getDocumentsAsync()
        let items = try snapshot.documents.compactMap { try $0.data(as: SearchHistory.self) }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func saveHistory(_ history: SearchHistory) async throws {
        try await collection.document(history.id ?? UUID().uuidString).setDataAsync(from: history, merge: true)
    }
}
