import SwiftUI

// MARK: - Admin Parking Lots List

struct AdminParkingLotsView: View {
    let dependencies: AppDependencies

    @StateObject private var viewModel: AdminParkingLotListViewModel
    @State private var isShowingForm = false
    @State private var selectedLot: ParkingLot?
    @State private var searchText = ""
    @State private var animateRows = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: AdminParkingLotListViewModel(
            parkingLotRepository: dependencies.parkingLotRepository
        ))
    }

    private var filteredLots: [ParkingLot] {
        guard !searchText.isEmpty else { return viewModel.parkingLots }
        let q = searchText.lowercased()
        return viewModel.parkingLots.filter {
            $0.name.lowercased().contains(q) ||
            $0.address.lowercased().contains(q) ||
            $0.district.lowercased().contains(q)
        }
    }

    private var availableCount: Int { viewModel.parkingLots.filter(\.isAvailable).count }
    private var fullCount: Int { viewModel.parkingLots.count - availableCount }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                listContent
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.canvasGradient.ignoresSafeArea())

                addFAB
            }
            .navigationTitle("Bãi xe")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Tìm tên, địa chỉ, quận..."
            )
        }
        .task {
            await viewModel.load()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateRows = true
            }
        }
        .sheet(isPresented: $isShowingForm) {
            ParkingLotEditorView(initialLot: selectedLot) { lot in
                Task { await viewModel.save(lot: lot) }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private var listContent: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            }

            if !viewModel.isLoading && !viewModel.parkingLots.isEmpty {
                ParkingLotsStatsStrip(
                    total: viewModel.parkingLots.count,
                    available: availableCount,
                    full: fullCount
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 10, trailing: 20))
            }

            if viewModel.isLoading {
                ForEach(0..<4, id: \.self) { _ in
                    AdminParkingLotSkeletonRow()
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(rowInsets)
                }
            } else if filteredLots.isEmpty {
                emptyStateRow
            } else {
                parkingLotRows
            }

            Color.clear
                .frame(height: 80)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isLoading)
    }

    private var rowInsets: EdgeInsets {
        EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateRow: some View {
        Group {
            if searchText.isEmpty {
                EmptyStateView(
                    title: "Chưa có bãi đỗ xe",
                    message: "Nhấn + để thêm bãi đỗ xe đầu tiên vào hệ thống",
                    systemImage: "car.2.fill"
                )
            } else {
                EmptyStateView(
                    title: "Không tìm thấy",
                    message: "Không có bãi xe khớp với \"\(searchText)\"",
                    systemImage: "magnifyingglass"
                )
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 24, leading: 20, bottom: 24, trailing: 20))
    }

    // MARK: - Parking Lot Rows

    @ViewBuilder
    private var parkingLotRows: some View {
        ForEach(Array(filteredLots.enumerated()), id: \.element.id) { index, lot in
            AdminParkingLotRow(lot: lot)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(rowInsets)
                .opacity(animateRows ? 1 : 0)
                .offset(y: animateRows ? 0 : 18)
                .animation(
                    .spring(response: 0.42, dampingFraction: 0.80)
                        .delay(Double(min(index, 7)) * 0.06),
                    value: animateRows
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        if let id = lot.id {
                            Task { await viewModel.delete(id: id) }
                        }
                    } label: {
                        Label("Xoá", systemImage: "trash.fill")
                    }

                    Button {
                        selectedLot = lot
                        isShowingForm = true
                    } label: {
                        Label("Sửa", systemImage: "pencil")
                    }
                    .tint(AppTheme.brand)
                }
                .contextMenu {
                    Button {
                        selectedLot = lot
                        isShowingForm = true
                    } label: {
                        Label("Chỉnh sửa", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        if let id = lot.id {
                            Task { await viewModel.delete(id: id) }
                        }
                    } label: {
                        Label("Xoá bãi xe", systemImage: "trash")
                    }
                }
        }
    }

    // MARK: - FAB

    private var addFAB: some View {
        Button {
            selectedLot = nil
            isShowingForm = true
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.heroGradient)
                    .frame(width: 58, height: 58)
                    .shadow(color: AppTheme.brand.opacity(0.42), radius: 18, x: 0, y: 8)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(ParkingFABButtonStyle())
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - Stats Strip

private struct ParkingLotsStatsStrip: View {
    let total: Int
    let available: Int
    let full: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ParkingStatChip(
                value: "\(total)",
                label: "Tổng số",
                color: AppTheme.brand,
                icon: "car.2.fill"
            )
            ParkingStatChip(
                value: "\(available)",
                label: "Còn chỗ",
                color: AppTheme.success,
                icon: "checkmark.circle.fill"
            )
            ParkingStatChip(
                value: "\(full)",
                label: "Hết chỗ",
                color: AppTheme.danger,
                icon: "xmark.circle.fill"
            )
        }
    }
}

private struct ParkingStatChip: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            AppTheme.elevatedCard,
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(color.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Parking Lot Row Card

private struct AdminParkingLotRow: View {
    let lot: ParkingLot

    private var occupancyColor: Color {
        if lot.occupancyRate < 0.6 { return AppTheme.success }
        if lot.occupancyRate < 0.85 { return AppTheme.warning }
        return AppTheme.danger
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topSection
            occupancySection
            tagsSection
        }
        .background(
            AppTheme.elevatedCard,
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 6)
    }

    private var topSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(lot.isAvailable
                          ? AppTheme.success.opacity(0.14)
                          : AppTheme.danger.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: "parkingsign")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(lot.isAvailable ? AppTheme.success : AppTheme.danger)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(lot.name)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                Text(lot.address)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            Text(lot.formattedPrice)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.brand)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.brand.opacity(0.10), in: Capsule())
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private var occupancySection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(lot.availableSpots) chỗ trống")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(occupancyColor)
                Spacer()
                Text("\(lot.availableSpots)/\(lot.totalSpots) chỗ")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.separator.opacity(2.5))
                        .frame(height: 4)
                    Capsule()
                        .fill(occupancyColor)
                        .frame(
                            width: max(4, geo.size.width * lot.occupancyRate),
                            height: 4
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: lot.occupancyRate)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private var tagsSection: some View {
        HStack(spacing: 6) {
            ParkingTag(
                title: lot.isAvailable ? "Còn chỗ" : "Hết chỗ",
                systemImage: lot.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill",
                color: lot.isAvailable ? AppTheme.success : AppTheme.danger
            )
            if lot.hasEVCharging {
                ParkingTag(title: "EV", systemImage: "bolt.car.fill", color: AppTheme.brand)
            }
            if lot.isOvernight {
                ParkingTag(title: "Qua đêm", systemImage: "moon.fill", color: AppTheme.warning)
            }
            if !lot.isOpen {
                ParkingTag(title: "Đóng cửa", systemImage: "xmark.octagon.fill", color: AppTheme.mutedText)
            }
        }
        .lineLimit(1)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.sm)
        .padding(.bottom, AppTheme.Spacing.lg)
    }
}

// MARK: - Loading Skeleton Row

private struct AdminParkingLotSkeletonRow: View {
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Circle()
                    .fill(AppTheme.separator)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.separator)
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.separator)
                        .frame(width: 160, height: 11)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.separator)
                    .frame(width: 60, height: 24)
            }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(AppTheme.separator)
                .frame(height: 4)

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.separator)
                    .frame(width: 68, height: 22)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.separator)
                    .frame(width: 46, height: 22)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.separator)
                    .frame(width: 78, height: 22)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            AppTheme.elevatedCard,
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .opacity(pulse ? 0.45 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - FAB Button Style

private struct ParkingFABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

// MARK: - Parking Lot Editor

struct ParkingLotEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let initialLot: ParkingLot?
    let onSave: (ParkingLot) -> Void

    @State private var name = ""
    @State private var address = ""
    @State private var district = ""
    @State private var city = "Ho Chi Minh City"
    @State private var latitude = "10.7769"
    @State private var longitude = "106.7009"
    @State private var hourlyRate = "20"
    @State private var availableSpots = "10"
    @State private var totalSpots = "50"
    @State private var isOpen = true
    @State private var hasEVCharging = false
    @State private var isOvernight = false
    @State private var amenities = "Indoor, CCTV"
    @State private var coverKey = DemoParkingCover.saigonCentre.rawValue

    private var isEditing: Bool { initialLot != nil }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !address.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                // Live Cover Preview
                Section {
                    ParkingLotHeroView(seed: coverKey, title: name.isEmpty ? "Tên bãi xe" : name)
                        .frame(height: 140)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))

                // Cover Picker
                Section {
                    Picker("Ảnh nền", selection: $coverKey) {
                        ForEach(DemoParkingCover.allCases, id: \.self) { preset in
                            Text(preset.title).tag(preset.rawValue)
                        }
                    }
                    Text("Sử dụng preset nội bộ — không cần Firebase Storage")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                } header: {
                    EditorSectionHeader(title: "Hình ảnh", icon: "photo.fill")
                }

                // Basic Info
                Section {
                    EditorTextField("Tên bãi xe", text: $name, icon: "building.2.fill")
                    EditorTextField("Địa chỉ chi tiết", text: $address, icon: "map.fill")
                    EditorTextField("Quận/Huyện", text: $district, icon: "location.fill")
                    EditorTextField("Thành phố", text: $city, icon: "building.columns.fill")
                } header: {
                    EditorSectionHeader(title: "Thông tin chính", icon: "info.circle.fill")
                }

                // Operations
                Section {
                    EditorTextField("Giá/giờ (nghìn đồng)", text: $hourlyRate, icon: "banknote.fill", keyboard: .decimalPad)
                    EditorTextField("Số chỗ trống hiện tại", text: $availableSpots, icon: "car.fill", keyboard: .numberPad)
                    EditorTextField("Tổng số chỗ đậu xe", text: $totalSpots, icon: "square.grid.3x3.fill", keyboard: .numberPad)
                } header: {
                    EditorSectionHeader(title: "Vận hành & Giá", icon: "gearshape.fill")
                }

                // Features / Toggles
                Section {
                    Toggle(isOn: $isOpen) {
                        Label("Đang hoạt động", systemImage: "door.garage.open")
                    }
                    .tint(AppTheme.success)

                    Toggle(isOn: $hasEVCharging) {
                        Label("Trạm sạc điện EV", systemImage: "bolt.car.fill")
                    }
                    .tint(AppTheme.brand)

                    Toggle(isOn: $isOvernight) {
                        Label("Cho phép đỗ qua đêm", systemImage: "moon.fill")
                    }
                    .tint(AppTheme.warning)
                } header: {
                    EditorSectionHeader(title: "Tính năng", icon: "star.fill")
                }

                // Amenities
                Section {
                    EditorTextField("VD: Indoor, CCTV, Bảo vệ 24/7", text: $amenities, icon: "list.bullet")
                } header: {
                    EditorSectionHeader(title: "Tiện ích", icon: "sparkles")
                }

                // Coordinates
                Section {
                    EditorTextField("Vĩ độ", text: $latitude, icon: "location.north.fill", keyboard: .decimalPad)
                    EditorTextField("Kinh độ", text: $longitude, icon: "location.north.line.fill", keyboard: .decimalPad)
                } header: {
                    EditorSectionHeader(title: "Tọa độ GPS", icon: "location.circle.fill")
                } footer: {
                    Text("Dùng để hiển thị vị trí trên bản đồ cho người dùng")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.canvasGradient.ignoresSafeArea())
            .navigationTitle(isEditing ? "Chỉnh sửa bãi xe" : "Thêm bãi xe mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Huỷ") { dismiss() }
                        .foregroundStyle(AppTheme.mutedText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveLot()
                        dismiss()
                    } label: {
                        Text("Lưu")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(canSave ? AppTheme.brand : AppTheme.mutedText)
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear { populateFields() }
        }
    }

    private func populateFields() {
        guard let lot = initialLot else { return }
        name = lot.name
        address = lot.address
        district = lot.district
        city = lot.city
        latitude = String(lot.latitude)
        longitude = String(lot.longitude)
        hourlyRate = String(Int(lot.hourlyRate))
        availableSpots = String(lot.availableSpots)
        totalSpots = String(lot.totalSpots)
        isOpen = lot.isOpen
        hasEVCharging = lot.hasEVCharging
        isOvernight = lot.isOvernight
        amenities = lot.amenities.joined(separator: ", ")
        coverKey = lot.demoImageKey ?? DemoParkingCover.saigonCentre.rawValue
    }

    private func saveLot() {
        let lot = ParkingLot(
            id: initialLot?.id,
            name: name,
            address: address,
            district: district,
            city: city,
            latitude: Double(latitude) ?? 0,
            longitude: Double(longitude) ?? 0,
            hourlyRate: Double(hourlyRate) ?? 0,
            availableSpots: Int(availableSpots) ?? 0,
            totalSpots: Int(totalSpots) ?? 0,
            isOpen: isOpen,
            hasEVCharging: hasEVCharging,
            isOvernight: isOvernight,
            imageURLs: ["demo://\(coverKey)"],
            amenities: amenities.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            createdAt: initialLot?.createdAt ?? .now,
            updatedAt: .now
        )
        onSave(lot)
    }
}

// MARK: - Editor Sub-components

private struct EditorSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.brand)
            .textCase(nil)
    }
}

private struct EditorTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboard: UIKeyboardType = .default

    init(_ placeholder: String, text: Binding<String>, icon: String? = nil, keyboard: UIKeyboardType = .default) {
        self.placeholder = placeholder
        _text = text
        self.icon = icon
        self.keyboard = keyboard
    }

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 22)
            }
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
        }
    }
}
