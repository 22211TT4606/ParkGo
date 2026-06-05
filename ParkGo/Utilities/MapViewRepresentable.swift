import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationService: LocationService
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        
        // Initial region setup
        if case .region(let region) = viewModel.cameraPosition {
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update user location visibility
        if uiView.showsUserLocation != (locationService.location != nil) {
            uiView.showsUserLocation = locationService.location != nil
        }
        
        // Diff annotations
        let currentAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
        let currentAnnotationLots = currentAnnotations.compactMap { ($0 as? ParkingLotAnnotation)?.lot }
        
        if currentAnnotationLots.count != viewModel.parkingLots.count ||
            Set(currentAnnotationLots.compactMap(\.id)) != Set(viewModel.parkingLots.compactMap(\.id)) {
            uiView.removeAnnotations(currentAnnotations)
            let annotations = viewModel.parkingLots.map { ParkingLotAnnotation(lot: $0) }
            uiView.addAnnotations(annotations)
        }
        
        // Handle selectedLot rendering updates
        for annotation in uiView.annotations {
            if let lotAnnotation = annotation as? ParkingLotAnnotation,
               let annotationView = uiView.view(for: lotAnnotation) {
                let isSelected = viewModel.selectedLot?.id == lotAnnotation.lot.id
                context.coordinator.updateAnnotationView(annotationView, for: lotAnnotation.lot, isSelected: isSelected)
            }
        }
        
        // Select or deselect selectedLot annotation in MKMapView
        if let selectedLot = viewModel.selectedLot {
            if let annotation = uiView.annotations.first(where: { ($0 as? ParkingLotAnnotation)?.lot.id == selectedLot.id }) {
                if !uiView.selectedAnnotations.contains(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) {
                    uiView.selectAnnotation(annotation, animated: true)
                }
            }
        } else {
            for annotation in uiView.selectedAnnotations {
                if !(annotation is MKUserLocation) {
                    uiView.deselectAnnotation(annotation, animated: true)
                }
            }
        }
        
        // Update polyline (route)
        let currentOverlays = uiView.overlays
        if let route = viewModel.route {
            if currentOverlays.isEmpty {
                uiView.addOverlay(route.polyline)
            } else if let currentPolyline = currentOverlays.first as? MKPolyline, currentPolyline !== route.polyline {
                uiView.removeOverlays(currentOverlays)
                uiView.addOverlay(route.polyline)
            }
        } else {
            if !currentOverlays.isEmpty {
                uiView.removeOverlays(currentOverlays)
            }
        }
        
        // Update camera position
        if let lastApplied = context.coordinator.lastAppliedCameraPosition, lastApplied == viewModel.cameraPosition {
            // Already applied this camera position, do not loop
        } else {
            context.coordinator.lastAppliedCameraPosition = viewModel.cameraPosition
            switch viewModel.cameraPosition {
            case .region(let region):
                uiView.setRegion(region, animated: true)
            case .rect(let rect):
                uiView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 200, right: 60), animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Thêm @MainActor ở đây để bảo vệ toàn bộ các hàm tương tác UI bên trong
    @MainActor
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        var lastAppliedCameraPosition: MapCameraPosition?
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            guard let lotAnnotation = annotation as? ParkingLotAnnotation else {
                return nil
            }
            
            let identifier = "ParkingLotAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: lotAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = lotAnnotation
            }
            
            let lot = lotAnnotation.lot
            let isSelected = parent.viewModel.selectedLot?.id == lot.id
            updateAnnotationView(annotationView!, for: lot, isSelected: isSelected)
            
            return annotationView
        }
        
        func updateAnnotationView(_ annotationView: MKAnnotationView, for lot: ParkingLot, isSelected: Bool) {
            // Remove previous hosting views to avoid leaks
            annotationView.subviews.forEach { $0.removeFromSuperview() }
            
            let markerView = ParkingMarker(
                lot: lot,
                isSelected: isSelected
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    self.parent.viewModel.selectedLot = (self.parent.viewModel.selectedLot?.id == lot.id) ? nil : lot
                    self.parent.viewModel.clearRoute()
                }
            }
            
            let hostingController = UIHostingController(rootView: markerView)
            hostingController.view.backgroundColor = .clear
            
            // Adjust frame size to match marker layout
            let width: CGFloat = isSelected ? 90 : 70
            let height: CGFloat = isSelected ? 60 : 45
            hostingController.view.frame = CGRect(x: -width / 2, y: -height, width: width, height: height)
            
            annotationView.addSubview(hostingController.view)
            annotationView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            annotationView.centerOffset = CGPoint(x: 0, y: -height / 2)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(AppTheme.brand)
                renderer.lineWidth = 5.0
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? ParkingLotAnnotation else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                parent.viewModel.selectedLot = annotation.lot
                parent.viewModel.clearRoute()
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Đã có @MainActor ở cấp độ class nên gán trực tiếp an toàn, không lo bóc tách luồng lỗi nữa
            self.parent.viewModel.visibleRegion = mapView.region
        }
    }
}

class ParkingLotAnnotation: NSObject, MKAnnotation {
    let lot: ParkingLot
    
    var coordinate: CLLocationCoordinate2D {
        lot.coordinate
    }
    
    var title: String? {
        lot.name
    }
    
    init(lot: ParkingLot) {
        self.lot = lot
    }
}
