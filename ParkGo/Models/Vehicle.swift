import Foundation
import FirebaseFirestore

enum VehicleType: String, Codable, CaseIterable {
    case sedan
    case suv
    case hatchback
    case motorcycle
    case van
}

struct Vehicle: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var plateNumber: String
    var brand: String
    var modelName: String
    var type: VehicleType
    var isElectric: Bool
    var colorName: String
    var createdAt: Date
    var updatedAt: Date
}
