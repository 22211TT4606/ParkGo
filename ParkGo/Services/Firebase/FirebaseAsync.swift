import Foundation
import FirebaseFirestore

// Firebase SDK 11+ provides native async/await. These thin wrappers
// keep the existing call-site names (`getDocumentsAsync`, etc.) while
// delegating to the native implementations instead of manual continuations.

extension Query {
    func getDocumentsAsync() async throws -> QuerySnapshot {
        try await getDocuments()
    }
}

extension DocumentReference {
    func getDocumentAsync() async throws -> DocumentSnapshot {
        try await getDocument()
    }

    func deleteAsync() async throws {
        try await delete()
    }

    func setDataAsync<T: Encodable>(from value: T, merge: Bool = true) async throws {
        try setData(from: value, merge: merge)
    }
}

extension WriteBatch {
    func commitAsync() async throws {
        try await commit()
    }
}
