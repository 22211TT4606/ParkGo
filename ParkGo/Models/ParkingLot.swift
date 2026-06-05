import Foundation
import CoreLocation
import FirebaseFirestore

struct ParkingLot: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var address: String
    var district: String
    var city: String
    var latitude: Double
    var longitude: Double
    var hourlyRate: Double
    var availableSpots: Int
    var totalSpots: Int
    var isOpen: Bool
    var hasEVCharging: Bool
    var isOvernight: Bool
    var imageURLs: [String]
    var amenities: [String]
    var createdAt: Date
    var updatedAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var occupancyRate: Double {
        guard totalSpots > 0 else { return 0 }
        return Double(totalSpots - availableSpots) / Double(totalSpots)
    }

    var isAvailable: Bool {
        isOpen && availableSpots > 0
    }

    var formattedPrice: String {
        "\(Int(hourlyRate))k/giờ"
    }

    var demoImageKey: String? {
        imageURLs.first?.replacingOccurrences(of: "demo://", with: "")
    }
}
