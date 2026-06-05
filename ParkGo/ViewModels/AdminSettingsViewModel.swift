import Foundation

@MainActor
final class AdminSettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var syncResult: SeedDataService.SyncResult?

    private let seedDataService: SeedDataService

    init(seedDataService: SeedDataService) {
        self.seedDataService = seedDataService
    }

    func seed() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await seedDataService.seedAllData()
            infoMessage = "Seed dữ liệu demo thành công."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sync() async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        syncResult = nil
        defer { isLoading = false }
        do {
            let result = try await seedDataService.syncMissingData()
            syncResult = result
            infoMessage = result.summary
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
