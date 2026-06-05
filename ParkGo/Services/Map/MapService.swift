import Foundation
import MapKit

final class MapService {
    func openInAppleMaps(for lot: ParkingLot) {
        let placemark = MKPlacemark(coordinate: lot.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = lot.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    func openCoordinateInAppleMaps(latitude: Double, longitude: Double, name: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

