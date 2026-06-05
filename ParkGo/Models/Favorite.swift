import Foundation
import FirebaseFirestore

struct Favorite: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var parkingLotID: String
    var createdAt: Date
}
