import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}

extension CLLocationDistance {
    var distanceText: String {
        if self < 1_000 {
            return "\(Int(self)) m"
        }
        return String(format: "%.1f km", self / 1_000)
    }
}

extension TimeInterval {
    var travelTimeText: String {
        let minutes = Int(self / 60)
        if minutes < 60 {
            return "\(minutes) phút"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0 ? "\(hours) giờ" : "\(hours) giờ \(remainingMinutes) phút"
    }
}

