import Foundation
import CoreLocation

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var pendingDirections: PendingDestination?
    @Published var pendingSearchFilter: SearchFilter?

    enum SearchFilter {
        case ev, overnight
    }

    struct PendingDestination: Equatable {
        let coordinate: CLLocationCoordinate2D
        let name: String

        static func == (lhs: PendingDestination, rhs: PendingDestination) -> Bool {
            lhs.name == rhs.name &&
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude
        }
    }

    func navigateToMap(destination: PendingDestination) {
        pendingDirections = destination
        selectedTab = 1
    }
}
