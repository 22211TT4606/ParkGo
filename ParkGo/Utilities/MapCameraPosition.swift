import Foundation
import MapKit

enum MapCameraPosition: Equatable {
    case region(MKCoordinateRegion)
    case rect(MKMapRect)
    
    var region: MKCoordinateRegion? {
        if case .region(let r) = self { return r }
        return nil
    }
    
    var rect: MKMapRect? {
        if case .rect(let r) = self { return r }
        return nil
    }
    
    static func == (lhs: MapCameraPosition, rhs: MapCameraPosition) -> Bool {
        switch (lhs, rhs) {
        case (.region(let l), .region(let r)):
            return l.center.latitude == r.center.latitude &&
                   l.center.longitude == r.center.longitude &&
                   l.span.latitudeDelta == r.span.latitudeDelta &&
                   l.span.longitudeDelta == r.span.longitudeDelta
        case (.rect(let l), .rect(let r)):
            return l.origin.x == r.origin.x &&
                   l.origin.y == r.origin.y &&
                   l.size.width == r.size.width &&
                   l.size.height == r.size.height
        default:
            return false
        }
    }
}
