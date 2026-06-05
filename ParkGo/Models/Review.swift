import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var parkingLotID: String
    var userID: String
    var userName: String
    var rating: Int
    var comment: String
    var createdAt: Date
}
