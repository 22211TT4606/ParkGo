import Foundation
import FirebaseFirestore

final class UserRepository {
    private lazy var collection = Firestore.firestore().collection("users")

    func fetchUser(userID: String) async throws -> UserProfile? {
        let snapshot = try await collection.document(userID).getDocumentAsync()
        return try snapshot.data(as: UserProfile.self)
    }

    func fetchAllUsers() async throws -> [UserProfile] {
        let snapshot = try await collection.order(by: "createdAt", descending: false).getDocumentsAsync()
        return try snapshot.documents.compactMap { try $0.data(as: UserProfile.self) }
    }

    func saveUser(_ user: UserProfile, userID: String) async throws {
        try await collection.document(userID).setDataAsync(from: user, merge: true)
    }
}
