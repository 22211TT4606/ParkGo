import Foundation

@MainActor
final class ParkingDetailViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isFavorite = false
    @Published var reviewText = ""
    @Published var rating = 5
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private let reviewRepository: ReviewRepository
    private let favoriteRepository: FavoriteRepository
    private let checkInRepository: CheckInRepository

    init(
        reviewRepository: ReviewRepository,
        favoriteRepository: FavoriteRepository,
        checkInRepository: CheckInRepository
    ) {
        self.reviewRepository = reviewRepository
        self.favoriteRepository = favoriteRepository
        self.checkInRepository = checkInRepository
    }

    func load(parkingLotID: String, userID: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            reviews = try await reviewRepository.fetchReviews(parkingLotID: parkingLotID)
            if let userID {
                isFavorite = try await favoriteRepository.isFavorite(userID: userID, parkingLotID: parkingLotID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(userID: String, parkingLotID: String) async {
        do {
            try await favoriteRepository.toggleFavorite(userID: userID, parkingLotID: parkingLotID)
            isFavorite.toggle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitCheckIn(userID: String, userName: String, parkingLotID: String, note: String, status: CheckInStatus) async {
        do {
            let item = CheckIn(userID: userID, userName: userName, parkingLotID: parkingLotID, note: note, status: status, createdAt: .now)
            try await checkInRepository.saveCheckIn(item)
            infoMessage = "Đã gửi check-in thành công."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitReview(userID: String, userName: String, parkingLotID: String) async {
        guard !reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            let review = Review(parkingLotID: parkingLotID, userID: userID, userName: userName, rating: rating, comment: reviewText, createdAt: .now)
            try await reviewRepository.saveReview(review)
            reviewText = ""
            reviews = try await reviewRepository.fetchReviews(parkingLotID: parkingLotID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

