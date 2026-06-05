import Foundation
import FirebaseFirestore

final class ReviewRepository {
    private lazy var collection = Firestore.firestore().collection("reviews")

    func fetchReviews(parkingLotID: String? = nil) async throws -> [Review] {
        let query: Query
        if let parkingLotID {
            query = collection.whereField("parkingLotID", isEqualTo: parkingLotID)
        } else {
            query = collection
        }

        let snapshot = try await query.getDocumentsAsync()
        let items = try snapshot.documents.compactMap { try $0.data(as: Review.self) }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func saveReview(_ review: Review) async throws {
        let document = collection.document(review.id ?? UUID().uuidString)
        try await document.setDataAsync(from: review, merge: true)
    }

    func deleteReview(id: String) async throws {
        try await collection.document(id).deleteAsync()
    }
}
