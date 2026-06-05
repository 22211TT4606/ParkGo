import SwiftUI

struct HomeView: View {
    let profile: UserProfile
    let dependencies: AppDependencies

    @StateObject private var viewModel: UserHomeViewModel
    @ObservedObject private var locationService: LocationService
    @State private var appearedOnce = false

    init(profile: UserProfile, dependencies: AppDependencies) {
        self.profile = profile
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: UserHomeViewModel(parkingLotRepository: dependencies.parkingLotRepository))
        locationService = dependencies.locationService
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Greeting Header
                        HomeGreetingHeader(profile: profile)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.top, AppTheme.Spacing.lg)
                            .padding(.bottom, AppTheme.Spacing.xl)

                        // Quick Metrics
                        HomeMetricsRow(
                            availableCount: viewModel.parkingLots.filter { $0.isAvailable }.count,
                            evCount: viewModel.parkingLots.filter { $0.hasEVCharging }.count,
                            overnightCount: viewModel.parkingLots.filter { $0.isOvernight }.count
                        )
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.bottom, AppTheme.Spacing.xl)

                        // Quick Actions
                        HomeQuickActionsRow(coordinator: dependencies.navigationCoordinator)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.bottom, AppTheme.Spacing.xxl)

                        // Error Banner
                        if let errorMessage = viewModel.errorMessage {
                            ErrorBanner(message: errorMessage)
                                .padding(.horizontal, AppTheme.Spacing.xl)
                                .padding(.bottom, AppTheme.Spacing.lg)
                        }

                        // Section Header
                        HomeSectionHeader(
                            title: "Bãi xe gần bạn",
                            count: viewModel.parkingLots.count,
                            isLoading: viewModel.isLoading
                        )
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.bottom, AppTheme.Spacing.md)

                        // Content
                        if viewModel.isLoading {
                            HomeParkingSkeletonView()
                                .padding(.horizontal, AppTheme.Spacing.xl)
                        } else if viewModel.parkingLots.isEmpty {
                            HomeEmptyState()
                                .padding(.horizontal, AppTheme.Spacing.xl)
                        } else {
                            LazyVStack(spacing: AppTheme.Spacing.md) {
                                ForEach(Array(viewModel.parkingLots.enumerated()), id: \.element.id) { index, lot in
                                    NavigationLink {
                                        ParkingLotDetailView(parkingLot: lot, profile: profile, dependencies: dependencies)
                                    } label: {
                                        ParkingLotCard(
                                            lot: lot,
                                            distanceText: locationText(for: lot),
                                            isFeatured: index == 0
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .opacity(appearedOnce ? 1 : 0)
                                    .offset(y: appearedOnce ? 0 : 24)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.82).delay(Double(index) * 0.06),
                                        value: appearedOnce
                                    )
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.xl)
                        }

                        Spacer(minLength: AppTheme.Spacing.xxl + 16)
                    }
                }
                .navigationTitle("")
                .navigationBarHidden(true)
            }
        }
        .task {
            locationService.requestPermission()
            await viewModel.loadLots(userLocation: locationService.location?.coordinate)
            withAnimation { appearedOnce = true }
        }
    }

    private func locationText(for lot: ParkingLot) -> String? {
        guard let userLocation = locationService.location?.coordinate else { return nil }
        return lot.coordinate.distance(to: userLocation).distanceText
    }
}

// MARK: - Greeting Header

private struct HomeGreetingHeader: View {
    let profile: UserProfile

    private var greetingPhrase: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Chào buổi sáng,"
        case 12..<18: return "Chào buổi chiều,"
        default: return "Chào buổi tối,"
        }
    }

    private var firstName: String {
        profile.fullName.components(separatedBy: " ").last ?? profile.fullName
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingPhrase)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.mutedText)

                Text(firstName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 7, height: 7)
                    Text("Tìm bãi xe theo thời gian thực")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.mutedText)
                }
                .padding(.top, 2)
            }

            Spacer()

            // Avatar
            ZStack {
                LinearGradient(
                    colors: [AppTheme.brandDark, AppTheme.brand, AppTheme.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(String(profile.fullName.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .shadow(color: AppTheme.brand.opacity(0.35), radius: 10, x: 0, y: 5)
            .overlay(
                Circle()
                    .stroke(.white, lineWidth: 2)
            )
        }
    }
}

// MARK: - Metrics Row

private struct HomeMetricsRow: View {
    let availableCount: Int
    let evCount: Int
    let overnightCount: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            HomeMetricPill(
                icon: "checkmark.circle.fill",
                value: "\(availableCount)",
                label: "Còn chỗ",
                color: AppTheme.success
            )
            HomeMetricPill(
                icon: "bolt.car.fill",
                value: "\(evCount)",
                label: "Sạc điện",
                color: AppTheme.brand
            )
            HomeMetricPill(
                icon: "moon.fill",
                value: "\(overnightCount)",
                label: "Qua đêm",
                color: AppTheme.warning
            )
        }
    }
}

private struct HomeMetricPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Quick Actions

private struct HomeQuickActionsRow: View {
    let coordinator: NavigationCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Truy cập nhanh")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.mutedText)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: AppTheme.Spacing.sm) {
                QuickActionButton(icon: "magnifyingglass", label: "Tìm kiếm", color: AppTheme.brand) {
                    coordinator.selectedTab = 2
                }
                QuickActionButton(icon: "map.fill", label: "Bản đồ", color: AppTheme.info) {
                    coordinator.selectedTab = 1
                }
                QuickActionButton(icon: "bolt.car.fill", label: "EV", color: AppTheme.success) {
                    coordinator.pendingSearchFilter = .ev
                    coordinator.selectedTab = 2
                }
                QuickActionButton(icon: "moon.stars.fill", label: "Qua đêm", color: AppTheme.warning) {
                    coordinator.pendingSearchFilter = .overnight
                    coordinator.selectedTab = 2
                }
            }
        }
    }
}

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(QuickActionButtonStyle())
    }
}

private struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Section Header

private struct HomeSectionHeader: View {
    let title: String
    let count: Int
    let isLoading: Bool

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)

            if !isLoading && count > 0 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.brand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.brand.opacity(0.12), in: Capsule())
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            if !isLoading {
                HStack(spacing: 3) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text("Gần nhất")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(AppTheme.brand)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: count)
    }
}

// MARK: - Skeleton Loading

private struct HomeParkingSkeletonView: View {
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                        .fill(AppTheme.field)
                        .frame(height: 160)

                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 7).fill(AppTheme.field).frame(width: 200, height: 15)
                        RoundedRectangle(cornerRadius: 7).fill(AppTheme.field).frame(width: 140, height: 12)
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 10).fill(AppTheme.field).frame(width: 70, height: 24)
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
                .opacity(shimmer ? 0.45 : 1.0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

// MARK: - Empty State

private struct HomeEmptyState: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppTheme.brand.opacity(0.1))
                    .frame(width: 88, height: 88)
                Image(systemName: "car.circle")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(AppTheme.heroGradient)
            }
            VStack(spacing: 8) {
                Text("Chưa có bãi xe")
                    .font(.system(size: 18, weight: .bold))
                Text("Hãy seed demo data hoặc kiểm tra kết nối Firestore.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.mutedText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 8)
    }
}
