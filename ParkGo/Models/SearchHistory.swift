import Foundation
import FirebaseFirestore

struct SearchHistory: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var keyword: String
    var filtersSummary: String
    var createdAt: Date
}
