import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var fullName: String
    var email: String
    var phoneNumber: String
    var role: UserRole
    var avatarURL: String?
    var preferredVehicleID: String?
    var preferredParkingStyle: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        fullName: String,
        email: String,
        phoneNumber: String = "",
        role: UserRole,
        avatarURL: String? = nil,
        preferredVehicleID: String? = nil,
        preferredParkingStyle: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phoneNumber = phoneNumber
        self.role = role
        self.avatarURL = avatarURL
        self.preferredVehicleID = preferredVehicleID
        self.preferredParkingStyle = preferredParkingStyle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
