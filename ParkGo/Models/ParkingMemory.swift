import Foundation
import FirebaseFirestore

struct ParkingMemory: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var parkingLotID: String?
    var parkingLotName: String
    var latitude: Double
    var longitude: Double
    var slotNote: String
    var createdAt: Date
}
