import SwiftUI
import MapKit
import UIKit

struct MapScreen: View {
    let profile: UserProfile
    let dependencies: AppDependencies

    @StateObject private var viewModel: MapViewModel
    @ObservedObject private var locationService: LocationService
    @ObservedObject private var coordinator: NavigationCoordinator
    @State private var hintVisible = true
    @State private var showLocationDeniedAlert = false
    @State private var navigationPath = NavigationPath()
    @State private var showAvailableLots = false

    init(profile: UserProfile, dependencies: AppDependencies) {
        self.profile = profile
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: MapViewModel(parkingLotRepository: dependencies.parkingLotRepository))
        locationService = dependencies.locationService
        coordinator = dependencies.navigationCoordinator
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Full-bleed map
                mapView

                // Top floating status bar
                VStack(spacing: 0) {
                    Button {
                        let available = viewModel.parkingLots.filter(\.isAvailable)
                        if !available.isEmpty { showAvailableLots = true }
                    } label: {
                        mapStatusBar
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 56)
                    Spacer()
                }

                // Zoom + location buttons
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 8) {
                        // Location button
                        Button {
                            if let coordinate = locationService.location?.coordinate {
                                viewModel.centerOnUser(coordinate)
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 44, height: 44)
                                .foregroundStyle(locationService.location != nil ? AppTheme.brand : .secondary)
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)

                        // Zoom buttons
                        VStack(spacing: 1) {
                            Button {
                                viewModel.zoom(in: true)
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(.primary)
                            }
                            Divider().frame(width: 44)
                            Button {
                                viewModel.zoom(in: false)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, viewModel.selectedLot == nil ? 100 : viewModel.route != nil ? 170 : 370)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Bottom selected lot card
                VStack {
                    Spacer()
                    if let selectedLot = viewModel.selectedLot {
                        if viewModel.route != nil {
                            routeBar(lot: selectedLot)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            selectedLotPanel(lot: selectedLot)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.78), value: viewModel.selectedLot?.id)
                .animation(.spring(response: 0.35, dampingFraction: 0.78), value: viewModel.route != nil)
            }
            .navigationBarHidden(true)
            .navigationDestination(for: ParkingLot.self) { lot in
                ParkingLotDetailView(parkingLot: lot, profile: profile, dependencies: dependencies)
            }
            .sheet(isPresented: $showAvailableLots) {
                let userCoord = locationService.location?.coordinate
                let available = viewModel.parkingLots.filter(\.isAvailable).sorted {
                    guard let userCoord else { return $0.name < $1.name }
                    return $0.coordinate.distance(to: userCoord) < $1.coordinate.distance(to: userCoord)
                }
                AvailableLotsSheet(
                    lots: available,
                    userLocation: locationService.location?.coordinate,
                    onSelect: { lot in
                        showAvailableLots = false
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                            viewModel.selectedLot = lot
                            hintVisible = false
                            viewModel.clearRoute()
                        }
                        if let userCoord = locationService.location?.coordinate {
                            Task { await viewModel.getDirections(from: userCoord, to: lot) }
                        } else {
                            viewModel.cameraPosition = .region(.init(
                                center: lot.coordinate,
                                span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
                            ))
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: coordinator.selectedTab) { tab in
            if tab != 1 {
                navigationPath = NavigationPath()
            }
        }
        .onChange(of: locationService.location) { newLocation in
            guard let coordinate = newLocation?.coordinate else { return }
            viewModel.centerOnUser(coordinate)
        }
        .onChange(of: coordinator.pendingDirections) { destination in
            guard let destination else { return }
            coordinator.pendingDirections = nil
            let lot = ParkingLot(
                id: nil, name: destination.name, address: "",
                district: "", city: "",
                latitude: destination.coordinate.latitude,
                longitude: destination.coordinate.longitude,
                hourlyRate: 0, availableSpots: 0, totalSpots: 0,
                isOpen: true, hasEVCharging: false, isOvernight: false,
                imageURLs: [], amenities: [], createdAt: .now, updatedAt: .now
            )
            viewModel.selectedLot = lot
            hintVisible = false
            if let userCoord = locationService.location?.coordinate {
                Task { await viewModel.getDirections(from: userCoord, to: lot) }
            } else {
                viewModel.cameraPosition = .region(.init(
                    center: destination.coordinate,
                    span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        }
        .onChange(of: locationService.authorizationStatus) { status in
            if status == .denied || status == .restricted {
                showLocationDeniedAlert = true
            }
        }
        .alert("Không có quyền truy cập vị trí", isPresented: $showLocationDeniedAlert) {
            Button("Mở Cài đặt") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Bỏ qua", role: .cancel) {}
        } message: {
            Text("Vui lòng vào Cài đặt > ParkGo > Vị trí và chọn \"Khi dùng ứng dụng\" để xem bãi xe gần bạn.")
        }
        .task {
            locationService.requestPermission()
            await viewModel.loadLots(userLocation: locationService.location?.coordinate)
            // Auto-dismiss hint after 4s once lots load
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            withAnimation(.easeOut(duration: 0.4)) { hintVisible = false }
        }
    }

    // MARK: - Map

    private var mapView: some View {
        MapViewRepresentable(viewModel: viewModel, locationService: locationService)
            .ignoresSafeArea()
    }

    // MARK: - Top Status Bar

    private var mapStatusBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(AppTheme.brand)
                Text("Đang tìm bãi xe...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            } else if !viewModel.parkingLots.isEmpty {
                ZStack {
                    Circle()
                        .fill(AppTheme.brand.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: "parkingsign")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.brand)
                }
                let available = viewModel.parkingLots.filter(\.isAvailable).count
                Group {
                    Text("\(available)")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(AppTheme.brand)
                    + Text(" / \(viewModel.parkingLots.count) bãi còn chỗ")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }
            } else if hintVisible {
                Image(systemName: "location.north.line.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.brand)
                Text("Chạm vào marker để xem bãi xe")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.28), lineWidth: 1))
        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .opacity(viewModel.isLoading || !viewModel.parkingLots.isEmpty || hintVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
        .animation(.easeInOut(duration: 0.3), value: viewModel.parkingLots.count)
    }

    // MARK: - Route Bar (compact, shown when route is active)

    private func routeBar(lot: ParkingLot) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 12)

            HStack(spacing: 12) {
                // Destination icon
                ZStack {
                    Circle()
                        .fill(AppTheme.brand.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "parkingsign")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.brand)
                }

                // Name + route stats
                VStack(alignment: .leading, spacing: 3) {
                    Text(lot.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if let route = viewModel.route {
                        HStack(spacing: 8) {
                            Label(route.distance.distanceText, systemImage: "arrow.triangle.swap")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Label(route.expectedTravelTime.travelTimeText, systemImage: "clock")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Cancel button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        viewModel.clearRoute()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.regularMaterial, in: Circle())
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 24,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: -8)
        )
    }

    // MARK: - Selected Lot Bottom Panel

    private func selectedLotPanel(lot: ParkingLot) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 6)

            Button {
                navigationPath.append(lot)
            } label: {
                ParkingLotCard(
                    lot: lot,
                    distanceText: locationService.location.map {
                        lot.coordinate.distance(to: $0.coordinate).distanceText
                    }
                )
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Directions button
            Button {
                if viewModel.route != nil {
                    viewModel.clearRoute()
                } else if let userCoord = locationService.location?.coordinate {
                    Task { await viewModel.getDirections(from: userCoord, to: lot) }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoadingRoute {
                        ProgressView()
                            .scaleEffect(0.85)
                            .tint(.white)
                    } else {
                        Image(systemName: viewModel.route != nil ? "xmark" : "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(viewModel.route != nil ? "Huỷ chỉ đường" : "Chỉ đường")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    viewModel.route != nil ? Color.secondary : AppTheme.brand,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .disabled(viewModel.isLoadingRoute || locationService.location == nil)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.lg)
            .padding(.top, 10)
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 24,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: -8)
        )
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    viewModel.selectedLot = nil
                    viewModel.clearRoute()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.regularMaterial, in: Circle())
            }
            .padding(.top, 10)
            .padding(.trailing, AppTheme.Spacing.lg)
        }
    }
}

// MARK: - Map Marker

struct ParkingMarker: View {
    let lot: ParkingLot
    let isSelected: Bool
    let onTap: () -> Void

    @State private var pulsing = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                ZStack {
                    // Pulse ring for available lots
                    if lot.isAvailable && !isSelected {
                        Circle()
                            .stroke(AppTheme.brand.opacity(pulsing ? 0 : 0.35), lineWidth: 2)
                            .frame(width: pulsing ? 52 : 36, height: pulsing ? 52 : 36)
                            .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulsing)
                    }

                    // Main marker pill
                    HStack(spacing: 4) {
                        Image(systemName: lot.isAvailable ? "car.fill" : "xmark")
                            .font(.system(size: 10, weight: .bold))
                        if lot.isAvailable {
                            Text("\(lot.availableSpots)")
                                .font(.system(size: 11, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, isSelected ? 14 : 10)
                    .padding(.vertical, isSelected ? 8 : 6)
                    .background(
                        lot.isAvailable
                            ? AnyShapeStyle(AppTheme.heroGradient)
                            : AnyShapeStyle(Color.secondary.opacity(0.85)),
                        in: Capsule()
                    )
                    .shadow(
                        color: (lot.isAvailable ? AppTheme.brand : Color.secondary).opacity(isSelected ? 0.45 : 0.25),
                        radius: isSelected ? 12 : 6, x: 0, y: isSelected ? 6 : 3
                    )
                    .scaleEffect(isSelected ? 1.18 : 1)
                }

                // Pointer triangle
                Triangle()
                    .fill(lot.isAvailable ? AppTheme.brand : Color.secondary.opacity(0.85))
                    .frame(width: 8, height: 5)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: isSelected)
        .onAppear { pulsing = true }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Available Lots Sheet

private struct AvailableLotsSheet: View {
    let lots: [ParkingLot]
    let userLocation: CLLocationCoordinate2D?
    let onSelect: (ParkingLot) -> Void

    private func distanceText(for lot: ParkingLot) -> String? {
        guard let userLocation else { return nil }
        return lot.coordinate.distance(to: userLocation).distanceText
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(AppTheme.brand.opacity(0.12)).frame(width: 36, height: 36)
                    Image(systemName: "parkingsign").font(.system(size: 15, weight: .bold)).foregroundStyle(AppTheme.brand)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bãi xe còn chỗ")
                        .font(.headline.weight(.bold))
                    Text("\(lots.count) bãi đang có chỗ trống")
                        .font(.caption).foregroundStyle(AppTheme.mutedText)
                }
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.md)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(lots) { lot in
                        Button {
                            onSelect(lot)
                        } label: {
                            AvailableLotRow(lot: lot, distanceText: distanceText(for: lot))
                        }
                        .buttonStyle(LotRowButtonStyle())

                        if lot.id != lots.last?.id {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
    }
}

private struct AvailableLotRow: View {
    let lot: ParkingLot
    let distanceText: String?

    var occupancyColor: Color {
        let rate = lot.occupancyRate
        if rate < 0.5 { return AppTheme.success }
        if rate < 0.85 { return AppTheme.warning }
        return AppTheme.danger
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(occupancyColor.opacity(0.12)).frame(width: 44, height: 44)
                VStack(spacing: 1) {
                    Text("\(lot.availableSpots)")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(occupancyColor)
                    Text("chỗ").font(.system(size: 9, weight: .medium)).foregroundStyle(occupancyColor.opacity(0.75))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(lot.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(lot.address)
                    .font(.caption).foregroundStyle(AppTheme.mutedText).lineLimit(1)
                HStack(spacing: 8) {
                    Text(lot.formattedPrice)
                        .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.brand)
                    if let distanceText {
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill").font(.system(size: 9))
                            Text(distanceText).font(.caption)
                        }
                        .foregroundStyle(AppTheme.info)
                    }
                }
            }

            Spacer()

            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.brand)
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct LotRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppTheme.brand.opacity(0.06) : .clear)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
