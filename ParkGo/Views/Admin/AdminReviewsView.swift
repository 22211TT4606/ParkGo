import SwiftUI

// MARK: - Main View

struct AdminReviewsView: View {
    let dependencies: AppDependencies

    @StateObject private var viewModel: AdminReviewsViewModel
    @State private var selectedRating: Int? = nil
    @State private var searchText: String = ""
    @State private var appearAnimation = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: AdminReviewsViewModel(reviewRepository: dependencies.reviewRepository)
        )
    }

    var filteredReviews: [Review] {
        var result = viewModel.reviews
        if let rating = selectedRating {
            result = result.filter { $0.rating == rating }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.userName.localizedCaseInsensitiveContains(searchText) ||
                $0.comment.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var averageRating: Double {
        guard !viewModel.reviews.isEmpty else { return 0 }
        let sum = viewModel.reviews.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(viewModel.reviews.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xl) {

                        if let errorMessage = viewModel.errorMessage {
                            ErrorBanner(message: errorMessage)
                                .padding(.horizontal, AppTheme.Spacing.xl)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        ReviewStatsHeader(
                            totalReviews: viewModel.reviews.count,
                            averageRating: averageRating
                        )
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 16)
                        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05), value: appearAnimation)

                        ReviewSearchBar(text: $searchText)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 16)
                            .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1), value: appearAnimation)

                        ReviewRatingFilter(selectedRating: $selectedRating)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : 16)
                            .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.15), value: appearAnimation)

                        if viewModel.isLoading {
                            ReviewsSkeletonList()
                                .padding(.horizontal, AppTheme.Spacing.xl)
                        } else if filteredReviews.isEmpty {
                            ReviewEmptyState(hasFilters: selectedRating != nil || !searchText.isEmpty)
                        } else {
                            LazyVStack(spacing: AppTheme.Spacing.md) {
                                ForEach(Array(filteredReviews.enumerated()), id: \.element.id) { index, review in
                                    ReviewCard(review: review) {
                                        if let id = review.id {
                                            Task { await viewModel.delete(id: id) }
                                        }
                                    }
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(y: appearAnimation ? 0 : 24)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.85)
                                            .delay(0.2 + Double(index) * 0.06),
                                        value: appearAnimation
                                    )
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.xl)
                        }

                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                }
            }
            .navigationTitle("Đánh giá")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.load()
            withAnimation { appearAnimation = true }
        }
    }
}

// MARK: - Stats Header

private struct ReviewStatsHeader: View {
    let totalReviews: Int
    let averageRating: Double

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ReviewStatPill(
                icon: "bubble.left.and.text.bubble.right.fill",
                value: "\(totalReviews)",
                label: "Tổng đánh giá",
                color: AppTheme.brand
            )
            ReviewStatPill(
                icon: "star.fill",
                value: averageRating > 0 ? String(format: "%.1f", averageRating) : "—",
                label: "Điểm trung bình",
                color: AppTheme.warning
            )
        }
    }
}

private struct ReviewStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title3.weight(.bold))
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Search Bar

private struct ReviewSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.mutedText)

            TextField("Tìm theo tên hoặc nội dung...", text: $text)
                .font(.body)

            if !text.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.25)) { text = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.mutedText)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, 13)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Rating Filter

private struct ReviewRatingFilter: View {
    @Binding var selectedRating: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                RatingFilterChip(label: "Tất cả", isSelected: selectedRating == nil, color: AppTheme.brand) {
                    withAnimation(.spring(response: 0.3)) { selectedRating = nil }
                }
                ForEach([5, 4, 3, 2, 1], id: \.self) { rating in
                    RatingFilterChip(
                        label: "\(rating) ★",
                        isSelected: selectedRating == rating,
                        color: ratingColor(rating)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedRating = selectedRating == rating ? nil : rating
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
    }

    private func ratingColor(_ rating: Int) -> Color {
        switch rating {
        case 5: return AppTheme.success
        case 4: return AppTheme.brand
        case 3: return AppTheme.warning
        case 2: return .orange
        default: return AppTheme.danger
        }
    }
}

private struct RatingFilterChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, 9)
                .background(
                    isSelected ? AnyShapeStyle(color) : AnyShapeStyle(color.opacity(0.1)),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1))
                .shadow(color: isSelected ? color.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isSelected ? 1.04 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Review Card

private struct ReviewCard: View {
    let review: Review
    let onDelete: () -> Void

    @State private var isPressed = false

    private var ratingColor: Color {
        switch review.rating {
        case 5: return AppTheme.success
        case 4: return AppTheme.brand
        case 3: return AppTheme.warning
        case 2: return .orange
        default: return AppTheme.danger
        }
    }

    private var initials: String {
        let parts = review.userName.split(separator: " ")
        if parts.count >= 2 {
            return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }
        return String(review.userName.prefix(2)).uppercased()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: review.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ratingColor.opacity(0.7), ratingColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                    Text(initials)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.headline.weight(.bold))
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(ratingColor)
                    Text("\(review.rating)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ratingColor)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(ratingColor.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(ratingColor.opacity(0.25), lineWidth: 1))
            }

            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= review.rating ? "star.fill" : "star")
                        .font(.system(size: 11))
                        .foregroundStyle(star <= review.rating ? ratingColor : AppTheme.mutedText.opacity(0.35))
                }
            }

            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 1)

            Text(review.comment)
                .font(.body)
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)

            HStack(spacing: 5) {
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.brand)
                Text(review.parkingLotID)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.brand)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.brand.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.brand.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 6)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isPressed)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Xoá", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Xoá đánh giá", systemImage: "trash")
            }
        }
        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 100) {} onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Skeleton Loading

private struct ReviewsSkeletonList: View {
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ForEach(0..<4, id: \.self) { _ in
                ReviewSkeletonCard(shimmer: shimmer)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
    }
}

private struct ReviewSkeletonCard: View {
    let shimmer: Bool

    var skeletonColor: Color {
        AppTheme.mutedText.opacity(shimmer ? 0.07 : 0.14)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                Circle().fill(skeletonColor).frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(skeletonColor).frame(width: 120, height: 13)
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(skeletonColor).frame(width: 80, height: 10)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(skeletonColor).frame(width: 48, height: 28)
            }
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(skeletonColor).frame(height: 11)
            RoundedRectangle(cornerRadius: 6, style: .continuous).fill(skeletonColor).frame(height: 11).padding(.trailing, 48)
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(skeletonColor).frame(width: 90, height: 26)
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.elevatedCard, in: RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
}

// MARK: - Empty State

private struct ReviewEmptyState: View {
    let hasFilters: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(AppTheme.brand.opacity(0.08))
                    .frame(width: 92, height: 92)
                Circle()
                    .fill(AppTheme.brand.opacity(0.04))
                    .frame(width: 116, height: 116)
                Image(systemName: hasFilters ? "magnifyingglass" : "star.bubble.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(AppTheme.brand.opacity(0.55))
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(hasFilters ? "Không tìm thấy đánh giá" : "Chưa có đánh giá")
                    .font(.title3.weight(.bold))

                Text(
                    hasFilters
                        ? "Thử điều chỉnh bộ lọc hoặc từ khóa."
                        : "Đánh giá sẽ hiển thị ở đây sau khi được gửi."
                )
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xxl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}
