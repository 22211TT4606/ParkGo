import Foundation
import FirebaseFirestore

enum CheckInStatus: String, Codable, CaseIterable {
    case normal
    case crowded
    case full
}

struct CheckIn: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var userName: String
    var parkingLotID: String
    var note: String
    var status: CheckInStatus
    var createdAt: Date
}
