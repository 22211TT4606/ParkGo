import SwiftUI

struct FavoritesScreen: View {
    let profile: UserProfile
    let dependencies: AppDependencies

    @StateObject private var viewModel: FavoritesViewModel
    @ObservedObject private var locationService: LocationService

    init(profile: UserProfile, dependencies: AppDependencies) {
        self.profile = profile
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: FavoritesViewModel(
                favoriteRepository: dependencies.favoriteRepository,
                parkingLotRepository: dependencies.parkingLotRepository
            )
        )
        locationService = dependencies.locationService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    FavoritesHeroHeader(count: viewModel.favorites.count, isLoaded: !viewModel.isLoading)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, AppTheme.Spacing.sm)

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    }

                    if viewModel.isLoading {
                        FavoritesSkeletonList()
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    } else if viewModel.favorites.isEmpty {
                        FavoritesEmptyState()
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.top, AppTheme.Spacing.sm)
                    } else {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(viewModel.favorites) { lot in
                                FavoriteItemRow(
                                    lot: lot,
                                    distanceText: locationService.location.map {
                                        lot.coordinate.distance(to: $0.coordinate).distanceText
                                    },
                                    onRemove: {
                                        Task {
                                            guard let userID = profile.id else { return }
                                            await viewModel.toggleFavorite(
                                                userID: userID,
                                                parkingLotID: lot.id ?? ""
                                            )
                                        }
                                    },
                                    profile: profile,
                                    dependencies: dependencies
                                )
                            }
                        }
                        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.favorites.count)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .refreshable {
                guard let userID = profile.id else { return }
                await viewModel.load(userID: userID)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: "#E11D48"))
                        Text("Yêu thích")
                            .font(.headline.weight(.semibold))
                    }
                }
            }
            .appScreenBackground()
        }
        .task {
            guard let userID = profile.id else { return }
            await viewModel.load(userID: userID)
        }
    }
}

// MARK: - Favorite Item Row

private struct FavoriteItemRow: View {
    let lot: ParkingLot
    let distanceText: String?
    let onRemove: () -> Void
    let profile: UserProfile
    let dependencies: AppDependencies

    @State private var appeared = false

    var body: some View {
        NavigationLink {
            ParkingLotDetailView(parkingLot: lot, profile: profile, dependencies: dependencies)
        } label: {
            ParkingLotCard(lot: lot, distanceText: distanceText)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onRemove) {
                Label("Xóa", systemImage: "heart.slash.fill")
            }
            .tint(Color(hex: "#E11D48"))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            withAnimation(.spring(response: 0.44, dampingFraction: 0.8).delay(0.06)) {
                appeared = true
            }
        }
    }
}

// MARK: - Hero Header

private struct FavoritesHeroHeader: View {
    let count: Int
    let isLoaded: Bool

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#BE123C"), Color(hex: "#F43F5E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color(hex: "#E11D48").opacity(0.32), radius: 10, x: 0, y: 5)
                Image(systemName: "heart.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Bãi xe đã lưu")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Quay lại nhanh điểm đỗ thường dùng")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
            }

            Spacer()

            if isLoaded && count > 0 {
                Text("\(count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(hex: "#E11D48"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#E11D48").opacity(0.1), in: Capsule())
                    .overlay(Capsule().stroke(Color(hex: "#E11D48").opacity(0.2), lineWidth: 1))
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.78), value: count)
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

// MARK: - Empty State

private struct FavoritesEmptyState: View {
    @State private var heartScale: CGFloat = 1

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#E11D48").opacity(0.06))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color(hex: "#E11D48").opacity(0.11))
                    .frame(width: 72, height: 72)
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#BE123C"), Color(hex: "#F43F5E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(heartScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                            heartScale = 1.12
                        }
                    }
            }

            VStack(spacing: 8) {
                Text("Chưa có bãi xe yêu thích")
                    .font(.title3.weight(.bold))
                Text("Thêm yêu thích từ màn chi tiết\nđể quay lại nhanh hơn.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Label("Mở Home để khám phá bãi xe", systemImage: "arrow.down.circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.brand)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.brand.opacity(0.1), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
        .premiumCard(radius: AppTheme.Radius.lg, padding: AppTheme.Spacing.xl)
    }
}

// MARK: - Skeleton

private struct FavoritesSkeletonList: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(0..<3, id: \.self) { i in
                FavoritesSkeletonCard()
                    .opacity(1 - Double(i) * 0.15)
            }
        }
    }
}

private struct FavoritesSkeletonCard: View {
    @State private var pulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .fill(AppTheme.separator)
                .frame(height: 154)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    RoundedRectangle(cornerRadius: 6).fill(AppTheme.separator).frame(width: 170, height: 15)
                    Spacer()
                    RoundedRectangle(cornerRadius: 6).fill(AppTheme.separator).frame(width: 56, height: 13)
                }
                RoundedRectangle(cornerRadius: 6).fill(AppTheme.separator).frame(width: 110, height: 11)
                RoundedRectangle(cornerRadius: 4).fill(AppTheme.separator).frame(height: 5)
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(AppTheme.separator).frame(width: 64, height: 24)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 0.5)
        )
        .opacity(pulsing ? 0.42 : 0.88)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}
