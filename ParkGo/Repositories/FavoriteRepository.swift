import Foundation
import FirebaseFirestore

final class FavoriteRepository {
    private lazy var collection = Firestore.firestore().collection("favorites")

    func fetchFavorites(userID: String) async throws -> [Favorite] {
        let snapshot = try await collection
            .whereField("userID", isEqualTo: userID)
            .getDocumentsAsync()
        return try snapshot.documents.compactMap { try $0.data(as: Favorite.self) }
    }

    func isFavorite(userID: String, parkingLotID: String) async throws -> Bool {
        let snapshot = try await collection
            .whereField("userID", isEqualTo: userID)
            .whereField("parkingLotID", isEqualTo: parkingLotID)
            .getDocumentsAsync()
        return !snapshot.documents.isEmpty
    }

    func toggleFavorite(userID: String, parkingLotID: String) async throws {
        let snapshot = try await collection
            .whereField("userID", isEqualTo: userID)
            .whereField("parkingLotID", isEqualTo: parkingLotID)
            .getDocumentsAsync()

        if let existing = snapshot.documents.first {
            try await existing.reference.deleteAsync()
        } else {
            let favorite = Favorite(userID: userID, parkingLotID: parkingLotID, createdAt: .now)
            try await collection.document().setDataAsync(from: favorite, merge: false)
        }
    }

    func saveFavorite(_ favorite: Favorite) async throws {
        try await collection.document(favorite.id ?? UUID().uuidString).setDataAsync(from: favorite, merge: true)
    }
}
