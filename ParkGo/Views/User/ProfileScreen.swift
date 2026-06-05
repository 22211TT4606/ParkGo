import SwiftUI
import CoreLocation

// MARK: - Profile Screen

struct ProfileScreen: View {
    let profile: UserProfile
    let dependencies: AppDependencies

    @EnvironmentObject private var appState: AppStateViewModel
    @StateObject private var viewModel: ProfileViewModel
    @ObservedObject private var locationService: LocationService
    @State private var isShowingVehicleEditor = false
    @State private var showChangePassword = false
    @State private var selectedVehicle: Vehicle?
    @State private var parkingNote = ""
    @State private var appearAnimation = false

    init(profile: UserProfile, dependencies: AppDependencies) {
        self.profile = profile
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: ProfileViewModel(
                profile: profile,
                authService: dependencies.authService,
                userRepository: dependencies.userRepository,
                vehicleRepository: dependencies.vehicleRepository,
                parkingHistoryRepository: dependencies.parkingHistoryRepository,
                parkingLotRepository: dependencies.parkingLotRepository
            )
        )
        locationService = dependencies.locationService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    feedbackBanners

                    profileHero
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .staggeredAppear(delay: 0.05, trigger: appearAnimation)

                    profileForm
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .staggeredAppear(delay: 0.12, trigger: appearAnimation)

                    vehiclesSection
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .staggeredAppear(delay: 0.19, trigger: appearAnimation)

                    parkingMemorySection
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .staggeredAppear(delay: 0.26, trigger: appearAnimation)

                    if !viewModel.recommendedLots.isEmpty {
                        recommendationsSection
                            .staggeredAppear(delay: 0.33, trigger: appearAnimation)
                    }

                    signOutButton
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .staggeredAppear(delay: 0.40, trigger: appearAnimation)
                }
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .navigationTitle("Hồ sơ")
            .appScreenBackground()
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingVehicleEditor) {
                VehicleEditorView(
                    initialVehicle: selectedVehicle,
                    userID: viewModel.profile.id ?? ""
                ) { vehicle in
                    Task { await viewModel.saveVehicle(vehicle) }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .task {
                locationService.requestPermission()
                await viewModel.load()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appearAnimation = true
                }
            }
        }
    }

    // MARK: - Feedback Banners

    @ViewBuilder
    private var feedbackBanners: some View {
        if let msg = viewModel.infoMessage {
            ProfileFeedbackBanner(message: msg, isError: false)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
        if let msg = viewModel.errorMessage {
            ErrorBanner(message: msg)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Profile Hero

    private var profileHero: some View {
        VStack(spacing: 0) {
            // Gradient banner
            ZStack {
                AppTheme.heroGradient
                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 110)
                    .offset(x: 90, y: 18)
                Circle()
                    .fill(.white.opacity(0.07))
                    .frame(width: 65)
                    .offset(x: 130, y: -14)
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 80)
                    .offset(x: -80, y: 20)
            }
            .frame(height: 82)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: AppTheme.Radius.xl,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: AppTheme.Radius.xl
                )
            )

            // Avatar + name block
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                    // Avatar overlapping banner
                    Text(String(viewModel.profile.fullName.prefix(1)).uppercased())
                        .font(.system(.title, design: .rounded, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 66, height: 66)
                        .background(AppTheme.heroGradient, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(color: AppTheme.brand.opacity(0.30), radius: 14, x: 0, y: 8)
                        .offset(y: -26)
                        .padding(.leading, AppTheme.Spacing.lg)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.profile.fullName)
                            .font(.title3.weight(.bold))
                            .lineLimit(1)
                        Text(viewModel.profile.email)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedText)
                            .lineLimit(1)
                        ParkingTag(
                            title: viewModel.profile.role.rawValue.capitalized,
                            systemImage: "person.badge.shield.checkmark.fill",
                            color: AppTheme.brand
                        )
                    }
                    .padding(.top, AppTheme.Spacing.sm)

                    Spacer()
                }
                .padding(.bottom, -AppTheme.Spacing.lg)

                // Stats strip
                HStack(spacing: 0) {
                    ProfileStatItem(value: "\(viewModel.vehicles.count)", label: "Xe")
                        .frame(maxWidth: .infinity)
                    Rectangle()
                        .fill(AppTheme.separator)
                        .frame(width: 1, height: 28)
                    ProfileStatItem(
                        value: viewModel.parkingMemory != nil ? "1" : "0",
                        label: "Vị trí lưu"
                    )
                    .frame(maxWidth: .infinity)
                    Rectangle()
                        .fill(AppTheme.separator)
                        .frame(width: 1, height: 28)
                    ProfileStatItem(
                        value: "\(viewModel.recommendedLots.count)",
                        label: "Gợi ý"
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(.top, AppTheme.Spacing.md)
            .background(AppTheme.elevatedCard)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: AppTheme.Radius.xl,
                    bottomTrailingRadius: AppTheme.Radius.xl,
                    topTrailingRadius: 0
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.09), radius: 20, x: 0, y: 12)
    }

    // MARK: - Profile Form

    private var profileForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ProfileSectionHeader(title: "Thông tin cá nhân", icon: "person.fill")

            ProfileFieldRow(
                label: "Họ tên",
                icon: "person.fill",
                value: Binding(
                    get: { viewModel.profile.fullName },
                    set: { viewModel.profile.fullName = $0 }
                )
            )

            ProfileFieldRow(
                label: "Email",
                icon: "envelope.fill",
                value: Binding(
                    get: { viewModel.profile.email },
                    set: { viewModel.profile.email = $0 }
                ),
                keyboard: .emailAddress,
                autocap: .never
            )

            ProfileFieldRow(
                label: "Số điện thoại",
                icon: "phone.fill",
                value: Binding(
                    get: { viewModel.profile.phoneNumber },
                    set: { viewModel.profile.phoneNumber = $0 }
                ),
                keyboard: .phonePad
            )

            Button {
                Task {
                    await viewModel.saveProfile()
                    await appState.refreshProfile()
                }
            } label: {
                Label("Lưu hồ sơ", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(PrimaryCTAButtonStyle())

            Button {
                showChangePassword = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Đổi mật khẩu")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(AppTheme.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(AppTheme.brand.opacity(0.09), in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous).stroke(AppTheme.brand.opacity(0.22), lineWidth: 1))
            }
        }
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
    }

    // MARK: - Vehicles Section

    private var vehiclesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                ProfileSectionHeader(title: "Xe của tôi", icon: "car.fill")
                Spacer()
                Button {
                    selectedVehicle = nil
                    isShowingVehicleEditor = true
                } label: {
                    Label("Thêm", systemImage: "plus")
                }
                .buttonStyle(SecondaryPillButtonStyle(tint: AppTheme.brand))
            }

            if viewModel.vehicles.isEmpty {
                EmptyStateView(
                    title: "Chưa có xe",
                    message: "Thêm xe để nhận gợi ý bãi đỗ phù hợp hơn",
                    systemImage: "car.fill"
                )
            } else {
                ForEach(viewModel.vehicles) { vehicle in
                    VehicleCard(vehicle: vehicle) {
                        selectedVehicle = vehicle
                        isShowingVehicleEditor = true
                    } onDelete: {
                        if let id = vehicle.id {
                            Task { await viewModel.deleteVehicle(id: id) }
                        }
                    }
                }
            }
        }
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
    }

    // MARK: - Parking Memory Section

    private var parkingMemorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ProfileSectionHeader(title: "Ghi nhớ vị trí đỗ xe", icon: "location.fill")

            ProfileFieldRow(
                label: "Ghi chú vị trí",
                icon: "note.text",
                value: $parkingNote
            )

            Button {
                Task {
                    await viewModel.saveParkingMemory(
                        lot: nil,
                        currentLocation: locationService.location?.coordinate,
                        note: parkingNote
                    )
                }
            } label: {
                Label(
                    locationService.location == nil ? "Chưa có vị trí GPS" : "Lưu vị trí hiện tại",
                    systemImage: locationService.location == nil ? "location.slash.fill" : "location.fill"
                )
            }
            .buttonStyle(PrimaryCTAButtonStyle())
            .disabled(locationService.location == nil)

            if let memory = viewModel.parkingMemory {
                ParkingMemoryCard(memory: memory) {
                    let coord = CLLocationCoordinate2D(
                        latitude: memory.latitude,
                        longitude: memory.longitude
                    )
                    dependencies.navigationCoordinator.navigateToMap(
                        destination: .init(coordinate: coord, name: memory.parkingLotName)
                    )
                }
            }
        }
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ProfileSectionHeader(title: "Gợi ý cho bạn", icon: "sparkles")
                .padding(.horizontal, AppTheme.Spacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(viewModel.recommendedLots) { lot in
                        NavigationLink {
                            ParkingLotDetailView(
                                parkingLot: lot,
                                profile: viewModel.profile,
                                dependencies: dependencies
                            )
                        } label: {
                            RecommendedLotCard(lot: lot)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button(role: .destructive) {
            appState.signOut()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Đăng xuất")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(AppTheme.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                AppTheme.danger.opacity(0.09),
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .stroke(AppTheme.danger.opacity(0.22), lineWidth: 1)
            )
        }
    }
}

// MARK: - Profile Stat Item

private struct ProfileStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.mutedText)
        }
    }
}

// MARK: - Profile Section Header

private struct ProfileSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.primary)
    }
}

// MARK: - Profile Field Row

private struct ProfileFieldRow: View {
    let label: String
    let icon: String
    @Binding var value: String
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedText)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 20)

                TextField(label, text: $value)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocap)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                AppTheme.field,
                in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
        }
    }
}

// MARK: - Vehicle Card

private struct VehicleCard: View {
    let vehicle: Vehicle
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var typeColor: Color {
        switch vehicle.type {
        case .sedan:      return AppTheme.brand
        case .suv:        return AppTheme.success
        case .hatchback:  return AppTheme.info
        case .motorcycle: return AppTheme.warning
        case .van:        return Color(hex: "#8B5CF6")
        }
    }

    private var typeIcon: String {
        switch vehicle.type {
        case .motorcycle: return "bicycle"
        case .van:        return "bus.fill"
        default:          return vehicle.isElectric ? "bolt.car.fill" : "car.fill"
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: typeIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(vehicle.plateNumber)
                    .font(.system(size: 16, weight: .bold))
                Text("\(vehicle.brand) \(vehicle.modelName)")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
                if vehicle.isElectric {
                    ParkingTag(title: "Xe điện", systemImage: "bolt.fill", color: AppTheme.brand)
                }
            }

            Spacer()

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Chỉnh sửa", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Xoá xe", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.mutedText)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            AppTheme.field,
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(typeColor.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Parking Memory Card

private struct ParkingMemoryCard: View {
    let memory: ParkingMemory
    let onNavigate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.info.opacity(0.14))
                        .frame(width: 42, height: 42)
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.info)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(memory.parkingLotName)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                    Text(memory.createdAt.shortDateText)
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }

                Spacer()
            }

            if !memory.slotNote.isEmpty {
                Text(memory.slotNote)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(2)
            }

            Button {
                onNavigate()
            } label: {
                Label("Tìm xe của tôi", systemImage: "figure.walk")
            }
            .buttonStyle(SecondaryPillButtonStyle(tint: AppTheme.info))
        }
        .padding(AppTheme.Spacing.md)
        .background(
            AppTheme.info.opacity(0.06),
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.info.opacity(0.20), lineWidth: 1)
        )
    }
}

// MARK: - Recommended Lot Card

private struct RecommendedLotCard: View {
    let lot: ParkingLot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ParkingLotHeroView(seed: lot.demoImageKey, title: lot.name)
                .frame(width: 200, height: 100)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: AppTheme.Radius.lg,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: AppTheme.Radius.lg
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(lot.name)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(lot.formattedPrice)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.brand)
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                    Text(lot.hasEVCharging ? "Có sạc EV" : "\(lot.availableSpots) chỗ trống")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .frame(width: 200)
        .background(
            AppTheme.elevatedCard,
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Feedback Banner

private struct ProfileFeedbackBanner: View {
    let message: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(
            LinearGradient(
                colors: isError
                    ? [AppTheme.danger, Color(hex: "#F97316")]
                    : [AppTheme.success, Color(hex: "#16A34A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
        )
        .shadow(
            color: (isError ? AppTheme.danger : AppTheme.success).opacity(0.22),
            radius: 14, x: 0, y: 8
        )
    }
}

// MARK: - Staggered Appear Modifier

private struct StaggeredAppearModifier: ViewModifier {
    let delay: Double
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .opacity(trigger ? 1 : 0)
            .offset(y: trigger ? 0 : 14)
            .animation(
                .spring(response: 0.48, dampingFraction: 0.80).delay(delay),
                value: trigger
            )
    }
}

private extension View {
    func staggeredAppear(delay: Double, trigger: Bool) -> some View {
        modifier(StaggeredAppearModifier(delay: delay, trigger: trigger))
    }
}

// MARK: - Change Password Sheet

private struct ChangePasswordSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrent = false
    @State private var showNew = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var isValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 6 && newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasGradient.ignoresSafeArea()

                VStack(spacing: AppTheme.Spacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.brand.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.brand)
                    }
                    .padding(.top, AppTheme.Spacing.md)

                    VStack(spacing: AppTheme.Spacing.sm) {
                        PasswordField(label: "Mật khẩu hiện tại", text: $currentPassword, show: $showCurrent)
                        PasswordField(label: "Mật khẩu mới (tối thiểu 6 ký tự)", text: $newPassword, show: $showNew)
                        PasswordField(label: "Xác nhận mật khẩu mới", text: $confirmPassword, show: .constant(showNew))

                        if newPassword.count > 0 && confirmPassword.count > 0 && newPassword != confirmPassword {
                            HStack(spacing: 5) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Mật khẩu xác nhận không khớp")
                                    .font(.caption)
                            }
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                        }

                        if let err = errorMessage {
                            HStack(spacing: 5) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(err)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(AppTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: "checkmark.lock.fill")
                            }
                            Text(isLoading ? "Đang lưu…" : "Xác nhận đổi mật khẩu")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background {
                            if isValid && !isLoading {
                                AppTheme.heroGradient
                            } else {
                                Color.gray.opacity(0.4)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                    }
                    .disabled(!isValid || isLoading)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                }
            }
            .navigationTitle("Đổi mật khẩu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") { dismiss() }
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
        }
    }

    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await viewModel.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PasswordField: View {
    let label: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedText)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 20)

                Group {
                    if show {
                        TextField(label, text: $text)
                    } else {
                        SecureField(label, text: $text)
                    }
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                Button {
                    show.toggle()
                } label: {
                    Image(systemName: show ? "eye.slash" : "eye")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.mutedText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.field, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous).stroke(AppTheme.separator, lineWidth: 1))
        }
    }
}

// MARK: - Vehicle Editor

struct VehicleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let initialVehicle: Vehicle?
    let userID: String
    let onSave: (Vehicle) -> Void

    @State private var plateNumber = ""
    @State private var brand = ""
    @State private var modelName = ""
    @State private var type: VehicleType = .sedan
    @State private var isElectric = false
    @State private var colorName = ""

    private var isEditing: Bool { initialVehicle != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VehicleEditorField("Biển số xe", text: $plateNumber, icon: "rectangle.and.text.magnifyingglass")
                    VehicleEditorField("Hãng xe (VD: Toyota)", text: $brand, icon: "building.2.fill")
                    VehicleEditorField("Mẫu xe (VD: Camry)", text: $modelName, icon: "car.fill")
                    VehicleEditorField("Màu xe (VD: Trắng)", text: $colorName, icon: "paintpalette.fill")
                } header: {
                    VehicleEditorSectionHeader(title: "Thông tin xe", icon: "car.fill")
                }

                Section {
                    Picker("Loại xe", selection: $type) {
                        ForEach(VehicleType.allCases, id: \.self) { t in
                            Text(t.rawValue.capitalized).tag(t)
                        }
                    }
                    Toggle(isOn: $isElectric) {
                        Label("Xe điện (EV)", systemImage: "bolt.car.fill")
                    }
                    .tint(AppTheme.brand)
                } header: {
                    VehicleEditorSectionHeader(title: "Phân loại", icon: "tag.fill")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.canvasGradient.ignoresSafeArea())
            .navigationTitle(isEditing ? "Chỉnh sửa xe" : "Thêm xe mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Huỷ") { dismiss() }
                        .foregroundStyle(AppTheme.mutedText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveVehicle()
                        dismiss()
                    } label: {
                        Text("Lưu")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.brand)
                    }
                }
            }
            .onAppear { populateFields() }
        }
    }

    private func populateFields() {
        guard let v = initialVehicle else { return }
        plateNumber = v.plateNumber
        brand = v.brand
        modelName = v.modelName
        type = v.type
        isElectric = v.isElectric
        colorName = v.colorName
    }

    private func saveVehicle() {
        let vehicle = Vehicle(
            id: initialVehicle?.id,
            userID: userID,
            plateNumber: plateNumber,
            brand: brand,
            modelName: modelName,
            type: type,
            isElectric: isElectric,
            colorName: colorName,
            createdAt: initialVehicle?.createdAt ?? .now,
            updatedAt: .now
        )
        onSave(vehicle)
    }
}

private struct VehicleEditorSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.brand)
            .textCase(nil)
    }
}

private struct VehicleEditorField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    init(_ placeholder: String, text: Binding<String>, icon: String? = nil) {
        self.placeholder = placeholder
        _text = text
        self.icon = icon
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
        }
    }
}
