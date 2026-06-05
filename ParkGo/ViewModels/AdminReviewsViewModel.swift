import Foundation

@MainActor
final class AdminReviewsViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let reviewRepository: ReviewRepository

    init(reviewRepository: ReviewRepository) {
        self.reviewRepository = reviewRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            reviews = try await reviewRepository.fetchReviews()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        do {
            try await reviewRepository.deleteReview(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

