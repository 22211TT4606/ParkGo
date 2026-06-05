import SwiftUI

// MARK: - Main View

struct AdminDashboardView: View {
    let dependencies: AppDependencies

    @StateObject private var viewModel: AdminDashboardViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: AdminDashboardViewModel(
                parkingLotRepository: dependencies.parkingLotRepository,
                userRepository: dependencies.userRepository,
                checkInRepository: dependencies.checkInRepository,
                reviewRepository: dependencies.reviewRepository
            )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    DashboardHeroCard()
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, AppTheme.Spacing.sm)

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    }

                    if viewModel.isLoading {
                        DashboardSkeletonSection()
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    } else {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            overviewSection
                            availabilitySection
                            activitySection
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .refreshable { await viewModel.load() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "parkingsign.circle.fill")
                            .foregroundStyle(AppTheme.brand)
                            .font(.subheadline.weight(.semibold))
                        Text("ParkGo Admin")
                            .font(.headline.weight(.semibold))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.callout.weight(.medium))
                    }
                    .tint(AppTheme.brand)
                }
            }
            .appScreenBackground()
        }
        .task { await viewModel.load() }
    }

    // MARK: - Sections

    private var overviewSection: some View {
        DashboardSection(title: "TỔNG QUAN", icon: "chart.bar.fill") {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppTheme.Spacing.md
            ) {
                StatCard(
                    title: "Bãi xe",
                    value: "\(viewModel.stats.totalParkingLots)",
                    systemImage: "car.fill",
                    tint: AppTheme.brand,
                    style: .gradient(AppTheme.brandDark, AppTheme.brand)
                )
                StatCard(
                    title: "Người dùng",
                    value: "\(viewModel.stats.totalUsers)",
                    systemImage: "person.2.fill",
                    tint: AppTheme.accent,
                    style: .gradient(Color(hex: "#0891B2"), AppTheme.accent)
                )
            }
        }
    }

    private var availabilitySection: some View {
        DashboardSection(title: "TRẠNG THÁI BÃI XE", icon: "parkingsign.circle.fill") {
            ParkingAvailabilityCard(
                total: viewModel.stats.totalParkingLots,
                available: viewModel.stats.availableLots,
                full: viewModel.stats.fullLots
            )
        }
    }

    private var activitySection: some View {
        DashboardSection(title: "HOẠT ĐỘNG", icon: "bolt.fill") {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppTheme.Spacing.md
            ) {
                StatCard(
                    title: "Check-ins",
                    value: "\(viewModel.stats.totalCheckIns)",
                    systemImage: "checkmark.bubble.fill",
                    tint: AppTheme.warning
                )
                StatCard(
                    title: "Đánh giá",
                    value: "\(viewModel.stats.totalReviews)",
                    systemImage: "star.bubble.fill",
                    tint: AppTheme.success
                )
            }
        }
    }
}

// MARK: - Hero Card

private struct DashboardHeroCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [AppTheme.brandDark, AppTheme.brand, AppTheme.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 170, height: 170)
                .offset(x: 140, y: -52)

            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 110, height: 110)
                .offset(x: 210, y: 30)

            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 64, height: 64)
                .offset(x: -14, y: 54)

            VStack(alignment: .leading, spacing: 9) {
                Label("QUẢN TRỊ VIÊN", systemImage: "shield.checkered")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.16), in: Capsule())

                Text("Bảng điều khiển")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(formattedToday)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.68))
            }
            .padding(AppTheme.Spacing.xl)
        }
        .frame(height: 158)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
        .shadow(color: AppTheme.brand.opacity(0.28), radius: 24, x: 0, y: 12)
    }

    private var formattedToday: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEEE, d MMM yyyy"
        return f.string(from: Date()).capitalized
    }
}

// MARK: - Section Header

private struct DashboardSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.brand)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedText)
                    .tracking(0.4)
                Spacer()
            }
            content()
        }
    }
}

// MARK: - Availability Card

private struct ParkingAvailabilityCard: View {
    let total: Int
    let available: Int
    let full: Int

    @State private var progressAnimated = false

    private var ratio: Double {
        total > 0 ? Double(available) / Double(total) : 0
    }

    private var statusColor: Color {
        ratio >= 0.5 ? AppTheme.success : (ratio > 0 ? AppTheme.warning : AppTheme.danger)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tình trạng hiện tại")
                        .font(.subheadline.weight(.semibold))
                    Text("Theo dõi chỗ trống theo thời gian thực")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }
                Spacer()
                Text("\(Int(ratio * 100))%")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(statusColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5), value: ratio)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.danger.opacity(0.14))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: ratio >= 0.5
                                    ? [Color(hex: "#16A34A"), AppTheme.success]
                                    : [AppTheme.warning, Color(hex: "#FCD34D")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressAnimated ? max(proxy.size.width * ratio, 8) : 8)
                        .animation(.spring(response: 0.85, dampingFraction: 0.76).delay(0.15), value: progressAnimated)
                }
            }
            .frame(height: 10)
            .onAppear { progressAnimated = true }
            .onChange(of: available) { _ in progressAnimated = false; progressAnimated = true }

            HStack {
                Label("\(available) còn chỗ", systemImage: "circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.success)
                    .labelStyle(DotLabelStyle(dotColor: AppTheme.success))
                Spacer()
                Label("\(full) hết chỗ", systemImage: "circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.danger)
                    .labelStyle(DotLabelStyle(dotColor: AppTheme.danger))
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

private struct DotLabelStyle: LabelStyle {
    let dotColor: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            Circle().fill(dotColor).frame(width: 7, height: 7)
            configuration.title
        }
    }
}

// MARK: - Skeleton Loading

private struct DashboardSkeletonSection: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            skeletonGroup(barWidth: 90, cardCount: 2, cardHeight: 112)
            skeletonGroup(barWidth: 130, cardCount: 1, cardHeight: 100)
            skeletonGroup(barWidth: 78, cardCount: 2, cardHeight: 112)
        }
    }

    private func skeletonGroup(barWidth: CGFloat, cardCount: Int, cardHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SkeletonPill(width: barWidth, height: 11)
            LazyVGrid(
                columns: cardCount == 1
                    ? [GridItem(.flexible())]
                    : [GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppTheme.Spacing.md
            ) {
                ForEach(0..<cardCount, id: \.self) { _ in
                    SkeletonPill(width: .infinity, height: cardHeight)
                }
            }
        }
    }
}

private struct SkeletonPill: View {
    let width: CGFloat
    let height: CGFloat
    @State private var pulsing = false

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
            .fill(AppTheme.separator)
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: height, maxHeight: height)
            .opacity(pulsing ? 0.45 : 0.9)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}
