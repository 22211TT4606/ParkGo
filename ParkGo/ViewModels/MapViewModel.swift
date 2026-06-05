import Foundation
import SwiftUI
import MapKit

@MainActor
final class MapViewModel: ObservableObject {
    @Published var parkingLots: [ParkingLot] = []
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 10.7769, longitude: 106.7009),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    var visibleRegion: MKCoordinateRegion?
    @Published var selectedLot: ParkingLot?
    @Published var route: MKRoute?
    @Published var isLoadingRoute = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let parkingLotRepository: ParkingLotRepository

    init(parkingLotRepository: ParkingLotRepository) {
        self.parkingLotRepository = parkingLotRepository
    }

    func getDirections(from userLocation: CLLocationCoordinate2D, to lot: ParkingLot) async {
        isLoadingRoute = true
        route = nil
        defer { isLoadingRoute = false }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: lot.coordinate))
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculate()
            route = response.routes.first
            if let polyline = response.routes.first?.polyline {
                let rect = polyline.boundingMapRect
                cameraPosition = .rect(rect.insetBy(dx: -rect.width * 0.25, dy: -rect.height * 0.25))
            }
        } catch {
            errorMessage = "Không thể tính đường đi: \(error.localizedDescription)"
        }
    }

    func clearRoute() {
        route = nil
    }

    func centerOnUser(_ coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ))
    }

    func zoom(in zoomIn: Bool) {
        let region = visibleRegion ?? cameraPosition.region
        guard let region else { return }
        let factor: Double = zoomIn ? 0.5 : 2.0
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(max(region.span.latitudeDelta * factor, 0.002), 90),
            longitudeDelta: min(max(region.span.longitudeDelta * factor, 0.002), 90)
        )
        cameraPosition = .region(MKCoordinateRegion(center: region.center, span: newSpan))
    }

    func loadLots(userLocation: CLLocationCoordinate2D?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            parkingLots = try await parkingLotRepository.fetchParkingLots()
            if let userLocation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                ))
            } else if let first = parkingLots.first {
                cameraPosition = .region(MKCoordinateRegion(
                    center: first.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                ))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

