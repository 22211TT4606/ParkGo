import SwiftUI

struct ParkingLotDetailView: View {
    let parkingLot: ParkingLot
    let profile: UserProfile
    let dependencies: AppDependencies

    @StateObject private var viewModel: ParkingDetailViewModel
    @State private var checkInNote = ""
    @State private var checkInStatus: CheckInStatus = .crowded

    init(parkingLot: ParkingLot, profile: UserProfile, dependencies: AppDependencies) {
        self.parkingLot = parkingLot
        self.profile = profile
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: ParkingDetailViewModel(
                reviewRepository: dependencies.reviewRepository,
                favoriteRepository: dependencies.favoriteRepository,
                checkInRepository: dependencies.checkInRepository
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                ParkingLotHeroView(seed: parkingLot.demoImageKey, title: parkingLot.name)
                    .frame(height: 220)

                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                }

                if let infoMessage = viewModel.infoMessage {
                    Label(infoMessage, systemImage: "checkmark.seal.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.success)
                }

                HStack(spacing: 12) {
                    Button {
                        if let userID = profile.id, let lotID = parkingLot.id {
                            Task { await viewModel.toggleFavorite(userID: userID, parkingLotID: lotID) }
                        }
                    } label: {
                        Label(viewModel.isFavorite ? "Đã yêu thích" : "Yêu thích", systemImage: viewModel.isFavorite ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryCTAButtonStyle())

                    Button {
                        dependencies.navigationCoordinator.navigateToMap(
                            destination: .init(
                                coordinate: parkingLot.coordinate,
                                name: parkingLot.name
                            )
                        )
                    } label: {
                        Label("Chỉ đường", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.brand)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                detailsCard
                checkInCard
                reviewComposer
                reviewList
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .navigationTitle("Chi tiết")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
        .task {
            await viewModel.load(parkingLotID: parkingLot.id ?? "", userID: profile.id)
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(parkingLot.address)
                .font(.headline.weight(.bold))
            Text("\(parkingLot.district), \(parkingLot.city)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)

            HStack(spacing: 8) {
                ParkingTag(title: parkingLot.formattedPrice, systemImage: "banknote.fill", color: AppTheme.brand)
                ParkingTag(title: "Còn \(parkingLot.availableSpots)/\(parkingLot.totalSpots) chỗ", systemImage: "parkingsign.circle.fill", color: parkingLot.isAvailable ? AppTheme.success : AppTheme.danger)
                if parkingLot.hasEVCharging {
                    ParkingTag(title: "EV Charging", systemImage: "bolt.car.fill", color: AppTheme.warning)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tiện ích")
                    .font(.headline.weight(.bold))
                FlowTagLayout(tags: parkingLot.amenities)
            }
        }
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
    }

    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Check-in tình trạng bãi xe")
                .font(.headline.weight(.bold))

            Picker("Tình trạng", selection: $checkInStatus) {
                Text("Bình thường").tag(CheckInStatus.normal)
                Text("Đông").tag(CheckInStatus.crowded)
                Text("Đầy").tag(CheckInStatus.full)
            }
            .pickerStyle(.segmented)

            TextField("Ghi chú nhanh", text: $checkInNote)
                .textFieldStyle(AppTextFieldStyle())

            Button {
                guard let userID = profile.id, let lotID = parkingLot.id else { return }
                Task {
                    await viewModel.submitCheckIn(
                        userID: userID,
                        userName: profile.fullName,
                        parkingLotID: lotID,
                        note: checkInNote,
                        status: checkInStatus
                    )
                    checkInNote = ""
                }
            } label: {
                Label("Gửi check-in", systemImage: "paperplane.fill")
            }
            .buttonStyle(PrimaryCTAButtonStyle())
        }
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
    }

    private var reviewComposer: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Thêm review")
                .font(.headline.weight(.bold))

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                        .font(.system(size: 30))
                        .foregroundStyle(star <= viewModel.rating ? .yellow : Color.secondary.opacity(0.35))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                viewModel.rating = star
                            }
                        }
                }
                Spacer()
                Text("\(viewModel.rating)/5")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            TextField("Chia sẻ trải nghiệm của bạn", text: $viewModel.reviewText, axis: .vertical)
                .lineLimit(3...5)
                .textFieldStyle(AppTextFieldStyle())

            Button {
                guard let userID = profile.id, let lotID = parkingLot.id else { return }
                Task { await viewModel.submitReview(userID: userID, userName: profile.fullName, parkingLotID: lotID) }
            } label: {
                Label("Gửi review", systemImage: "star.bubble.fill")
            }
            .buttonStyle(SecondaryPillButtonStyle(tint: AppTheme.brand))
        }
        .premiumCard(radius: AppTheme.Radius.xl, padding: AppTheme.Spacing.lg)
    }

    private var reviewList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Review gần đây")
                .font(.headline.weight(.bold))

            if viewModel.reviews.isEmpty {
                EmptyStateView(title: "Chưa có review", message: "Hãy là người đầu tiên để lại đánh giá.", systemImage: "text.bubble")
            } else {
                ForEach(viewModel.reviews) { review in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack {
                            Text(review.userName)
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Text(String(repeating: "★", count: review.rating))
                                .foregroundStyle(AppTheme.warning)
                        }
                        Text(review.comment)
                            .font(.subheadline)
                        Text(review.createdAt.shortDateText)
                            .font(.caption)
                            .foregroundStyle(AppTheme.mutedText)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.field, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                }
            }
        }
    }
}

struct FlowTagLayout: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .foregroundStyle(AppTheme.brand)
                    .background(AppTheme.brand.opacity(0.10), in: Capsule())
            }
        }
    }
}
