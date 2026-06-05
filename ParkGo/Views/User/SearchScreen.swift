import SwiftUI

struct SearchScreen: View {
    let profile: UserProfile
    let dependencies: AppDependencies

    @StateObject private var viewModel: SearchViewModel
    @ObservedObject private var locationService: LocationService
    @ObservedObject private var coordinator: NavigationCoordinator
    @State private var appearAnimation = false

    init(profile: UserProfile, dependencies: AppDependencies) {
        self.profile = profile
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: SearchViewModel(
                parkingLotRepository: dependencies.parkingLotRepository,
                searchHistoryRepository: dependencies.searchHistoryRepository
            )
        )
        locationService = dependencies.locationService
        coordinator = dependencies.navigationCoordinator
    }

    private var activeFilterCount: Int {
        [viewModel.filters.onlyEVCharging,
         viewModel.filters.onlyOvernight,
         viewModel.filters.underTwenty,
         viewModel.filters.onlyAvailable].filter { $0 }.count
    }

    private var isIdle: Bool {
        viewModel.query.isEmpty && activeFilterCount == 0
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    filterSection

                    if viewModel.isLoading {
                        SearchSkeletonSection()
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    } else {
                        resultsSection
                        if viewModel.query.isEmpty && activeFilterCount == 0 {
                            historySection
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .navigationTitle("Tìm kiếm")
            .appScreenBackground()
            .searchable(text: $viewModel.query, prompt: "Tên bãi xe hoặc địa chỉ")
            .onSubmit(of: .search) {
                if let userID = profile.id {
                    Task { await viewModel.saveSearch(userID: userID) }
                }
            }
            .onChange(of: viewModel.query) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
                    viewModel.applyFilters(userLocation: locationService.location?.coordinate)
                }
            }
            .animation(.spring(response: 0.3), value: viewModel.query.isEmpty)
        }
        .onChange(of: coordinator.pendingSearchFilter) { filter in
            guard let filter else { return }
            coordinator.pendingSearchFilter = nil
            viewModel.filters = ParkingSearchFilters()
            switch filter {
            case .ev:       viewModel.filters.onlyEVCharging = true
            case .overnight: viewModel.filters.onlyOvernight = true
            }
            viewModel.applyFilters(userLocation: locationService.location?.coordinate)
        }
        .task {
            guard let userID = profile.id else { return }
            await viewModel.load(userID: userID, userLocation: locationService.location?.coordinate)
            withAnimation { appearAnimation = true }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bộ lọc thông minh")
                        .font(.headline.weight(.bold))
                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount) bộ lọc đang áp dụng")
                            .font(.caption)
                            .foregroundStyle(AppTheme.brand)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                Spacer()
                if activeFilterCount > 0 {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.filters = ParkingSearchFilters()
                            viewModel.applyFilters(userLocation: locationService.location?.coordinate)
                        }
                    } label: {
                        Label("Đặt lại", systemImage: "xmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.danger.opacity(0.1), in: Capsule())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: activeFilterCount)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    SmartFilterChip(
                        title: "Sạc điện", icon: "bolt.car.fill",
                        isOn: viewModel.filters.onlyEVCharging, color: AppTheme.brand
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            viewModel.filters.onlyEVCharging.toggle()
                            viewModel.applyFilters(userLocation: locationService.location?.coordinate)
                        }
                    }
                    SmartFilterChip(
                        title: "Qua đêm", icon: "moon.fill",
                        isOn: viewModel.filters.onlyOvernight, color: AppTheme.warning
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            viewModel.filters.onlyOvernight.toggle()
                            viewModel.applyFilters(userLocation: locationService.location?.coordinate)
                        }
                    }
                    SmartFilterChip(
                        title: "<20k/giờ", icon: "tag.fill",
                        isOn: viewModel.filters.underTwenty, color: AppTheme.success
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            viewModel.filters.underTwenty.toggle()
                            viewModel.applyFilters(userLocation: locationService.location?.coordinate)
                        }
                    }
                    SmartFilterChip(
                        title: "Còn chỗ", icon: "checkmark.circle.fill",
                        isOn: viewModel.filters.onlyAvailable, color: AppTheme.success
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            viewModel.filters.onlyAvailable.toggle()
                            viewModel.applyFilters(userLocation: locationService.location?.coordinate)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 16)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05), value: appearAnimation)
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isIdle ? "Gần bạn nhất" : "Kết quả")
                        .font(.headline.weight(.bold))
                    if !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("cho \"\(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines))\"")
                            .font(.caption)
                            .foregroundStyle(AppTheme.brand)
                            .lineLimit(1)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else if isIdle {
                        Text("10 bãi xe gần nhất")
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedText)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.spring(response: 0.3), value: viewModel.query)
                .animation(.spring(response: 0.3), value: isIdle)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.brand)
                    Text("\(viewModel.results.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.brand)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(AppTheme.brand.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(AppTheme.brand.opacity(0.2), lineWidth: 1))
                .animation(.spring(response: 0.3), value: viewModel.results.count)
            }

            if viewModel.results.isEmpty {
                SearchEmptyState()
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, lot in
                        NavigationLink {
                            ParkingLotDetailView(parkingLot: lot, profile: profile, dependencies: dependencies)
                        } label: {
                            ParkingLotCard(
                                lot: lot,
                                distanceText: locationService.location.map {
                                    lot.coordinate.distance(to: $0.coordinate).distanceText
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 24)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.85)
                                .delay(0.1 + Double(index) * 0.07),
                            value: appearAnimation
                        )
                    }
                }
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 16)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1), value: appearAnimation)
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Lịch sử tìm kiếm")
                    .font(.headline.weight(.bold))
                Spacer()
                if !viewModel.history.isEmpty {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText.opacity(0.6))
                }
            }

            if viewModel.history.isEmpty {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "clock")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.mutedText.opacity(0.45))
                    Text("Chưa có lịch sử tìm kiếm.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedText)
                }
                .padding(.vertical, AppTheme.Spacing.sm)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.history.prefix(5).enumerated()), id: \.element.id) { index, item in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.query = item.keyword
                                viewModel.applyFilters(userLocation: locationService.location?.coordinate)
                            }
                        } label: {
                            SearchHistoryRow(item: item)
                        }
                        .buttonStyle(.plain)

                        if index < min(viewModel.history.count, 5) - 1 {
                            Divider().padding(.leading, 50)
                        }
                    }
                }
            }
        }
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 16)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.15), value: appearAnimation)
    }
}

// MARK: - Smart Filter Chip

private struct SmartFilterChip: View {
    let title: String
    let icon: String
    let isOn: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.footnote.weight(.bold))
            }
            .foregroundStyle(isOn ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isOn
                    ? AnyShapeStyle(LinearGradient(colors: [color, color.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(color.opacity(0.1)),
                in: Capsule()
            )
            .overlay(Capsule().stroke(isOn ? Color.clear : color.opacity(0.25), lineWidth: 1))
            .shadow(color: isOn ? color.opacity(0.32) : .clear, radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isOn ? 1.04 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isOn)
    }
}

// MARK: - History Row

private struct SearchHistoryRow: View {
    let item: SearchHistory
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 34, height: 34)
                .background(AppTheme.brand.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(item.keyword.isEmpty ? "Tìm kiếm không từ khóa" : item.keyword)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(item.filtersSummary) • \(item.createdAt.shortDateText)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "arrow.up.left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedText.opacity(0.45))
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.25), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 100) {} onPressingChanged: { isPressed = $0 }
    }
}

// MARK: - Empty State

private struct SearchEmptyState: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle().fill(AppTheme.brand.opacity(0.06)).frame(width: 108, height: 108)
                Circle().fill(AppTheme.brand.opacity(0.1)).frame(width: 80, height: 80)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(AppTheme.brand.opacity(0.55))
            }
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Không tìm thấy bãi xe")
                    .font(.headline.weight(.bold))
                Text("Thử đổi bộ lọc hoặc từ khóa tìm kiếm khác.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Loading Skeleton

private struct SearchSkeletonSection: View {
    @State private var shimmer = false

    var color: Color { AppTheme.mutedText.opacity(shimmer ? 0.07 : 0.14) }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                SearchCardSkeleton(color: color)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

private struct SearchCardSkeleton: View {
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .fill(color)
                .frame(height: 154)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color).frame(width: 160, height: 14)
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color).frame(width: 110, height: 11)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color).frame(width: 58, height: 14)
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(color).frame(width: 40, height: 11)
                }
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color).frame(width: 68, height: 26)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            AppTheme.elevatedCard,
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
}
