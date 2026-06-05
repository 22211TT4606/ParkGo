import Foundation
import FirebaseFirestore

final class SeedDataService {
    private let authService: AuthService
    private let userRepository: UserRepository
    private let parkingLotRepository: ParkingLotRepository
    private let reviewRepository: ReviewRepository
    private let favoriteRepository: FavoriteRepository
    private let vehicleRepository: VehicleRepository
    private let checkInRepository: CheckInRepository
    private let searchHistoryRepository: SearchHistoryRepository
    private let parkingHistoryRepository: ParkingHistoryRepository

    init(
        authService: AuthService,
        userRepository: UserRepository,
        parkingLotRepository: ParkingLotRepository,
        reviewRepository: ReviewRepository,
        favoriteRepository: FavoriteRepository,
        vehicleRepository: VehicleRepository,
        checkInRepository: CheckInRepository,
        searchHistoryRepository: SearchHistoryRepository,
        parkingHistoryRepository: ParkingHistoryRepository
    ) {
        self.authService = authService
        self.userRepository = userRepository
        self.parkingLotRepository = parkingLotRepository
        self.reviewRepository = reviewRepository
        self.favoriteRepository = favoriteRepository
        self.vehicleRepository = vehicleRepository
        self.checkInRepository = checkInRepository
        self.searchHistoryRepository = searchHistoryRepository
        self.parkingHistoryRepository = parkingHistoryRepository
    }

    func seedAllData() async throws {
        // Client-side seed is intentionally demo-focused: it creates auth users one by one,
        // writes matching Firestore profiles, then populates all required collections.
        let admin = DemoSeedData.adminCredential
        let accounts = [admin] + DemoSeedData.userCredentials
        var userIDsByEmail: [String: String] = [:]

        for account in accounts {
            let uid = try await ensureAccountExists(account)
            userIDsByEmail[account.email] = uid
        }

        for lot in DemoSeedData.parkingLots {
            try await parkingLotRepository.saveParkingLot(lot)
        }

        let minhID = userIDsByEmail["minh@parkgo.demo"] ?? ""
        let linhID = userIDsByEmail["linh@parkgo.demo"] ?? ""
        let baoID = userIDsByEmail["bao@parkgo.demo"] ?? ""
        let thuID = userIDsByEmail["thu@parkgo.demo"] ?? ""
        let namID = userIDsByEmail["nam@parkgo.demo"] ?? ""

        func resolve(_ seedID: String) -> String {
            resolvedSeedUserID(seedID, minhID: minhID, linhID: linhID, baoID: baoID, thuID: thuID, namID: namID)
        }

        for source in DemoSeedData.vehicles {
            var vehicle = source
            vehicle.userID = resolve(source.userID)
            try await vehicleRepository.saveVehicle(vehicle)
        }

        for source in DemoSeedData.reviews {
            var review = source
            review.userID = resolve(source.userID)
            try await reviewRepository.saveReview(review)
        }

        for source in DemoSeedData.favorites {
            var favorite = source
            favorite.userID = resolve(source.userID)
            try await favoriteRepository.saveFavorite(favorite)
        }

        for source in DemoSeedData.checkIns {
            var checkIn = source
            checkIn.userID = resolve(source.userID)
            try await checkInRepository.saveCheckIn(checkIn)
        }

        for source in DemoSeedData.searchHistory {
            var history = source
            history.userID = resolve(source.userID)
            try await searchHistoryRepository.saveHistory(history)
        }

        for source in DemoSeedData.parkingMemories {
            var memory = source
            memory.userID = resolve(source.userID)
            try await parkingHistoryRepository.saveMemory(memory)
        }

        _ = try await authService.signIn(email: admin.email, password: admin.password)
    }

    private func ensureAccountExists(_ credential: DemoCredential) async throws -> String {
        do {
            let uid = try await authService.signIn(email: credential.email, password: credential.password)
            try await saveProfile(userID: uid, credential: credential)
            return uid
        } catch {
            let uid = try await authService.register(email: credential.email, password: credential.password)
            try await saveProfile(userID: uid, credential: credential)
            return uid
        }
    }

    private func saveProfile(userID: String, credential: DemoCredential) async throws {
        let profile = UserProfile(
            id: userID,
            fullName: credential.fullName,
            email: credential.email,
            phoneNumber: credential.phoneNumber,
            role: credential.role,
            createdAt: .now,
            updatedAt: .now
        )
        try await userRepository.saveUser(profile, userID: userID)
    }

    private func resolvedSeedUserID(_ seedID: String, minhID: String, linhID: String, baoID: String, thuID: String, namID: String) -> String {
        switch seedID {
        case "seed_minh": return minhID
        case "seed_linh": return linhID
        case "seed_bao": return baoID
        case "seed_thu": return thuID
        case "seed_nam": return namID
        default: return seedID
        }
    }

    // MARK: - Sync Missing Data (skip if already exists)

    /// Sync result with per-collection counts of newly created items
    struct SyncResult {
        var newLots = 0
        var newUsers = 0
        var newReviews = 0
        var newFavorites = 0
        var newVehicles = 0
        var newCheckIns = 0

        var totalNew: Int { newLots + newUsers + newReviews + newFavorites + newVehicles + newCheckIns }

        var summary: String {
            guard totalNew > 0 else { return "Tất cả dữ liệu đã tồn tại, không có gì mới." }
            var parts: [String] = []
            if newLots > 0      { parts.append("\(newLots) bãi xe") }
            if newUsers > 0     { parts.append("\(newUsers) tài khoản") }
            if newReviews > 0   { parts.append("\(newReviews) review") }
            if newFavorites > 0 { parts.append("\(newFavorites) yêu thích") }
            if newVehicles > 0  { parts.append("\(newVehicles) xe") }
            if newCheckIns > 0  { parts.append("\(newCheckIns) check-in") }
            return "Đã thêm: " + parts.joined(separator: ", ") + "."
        }
    }

    func syncMissingData() async throws -> SyncResult {
        var result = SyncResult()
        let db = Firestore.firestore()

        // 1. Check user existence via Firestore (NOT sign-in) to avoid auth state flicker.
        //    Only register accounts that are truly missing from the `users` collection.
        let admin = DemoSeedData.adminCredential
        let accounts = [admin] + DemoSeedData.userCredentials
        var userIDsByEmail: [String: String] = [:]

        let existingUsers = try await userRepository.fetchAllUsers()
        let existingEmails = Dictionary(uniqueKeysWithValues: existingUsers.compactMap { u -> (String, String)? in
            guard let id = u.id else { return nil }
            return (u.email, id)
        })

        for account in accounts {
            if let uid = existingEmails[account.email] {
                // User already in Firestore — reuse UID, no sign-in needed
                userIDsByEmail[account.email] = uid
            } else {
                // Not found — register (first time only, unavoidable auth event)
                let uid = try await authService.register(email: account.email, password: account.password)
                try await saveProfile(userID: uid, credential: account)
                userIDsByEmail[account.email] = uid
                result.newUsers += 1
            }
        }

        // 2. Parking lots — check each by document ID
        let lotsCollection = db.collection("parking_lots")
        for lot in DemoSeedData.parkingLots {
            let docID = lot.id ?? UUID().uuidString
            let snap = try await lotsCollection.document(docID).getDocumentAsync()
            guard !snap.exists else { continue }
            try await parkingLotRepository.saveParkingLot(lot)
            result.newLots += 1
        }

        let minhID = userIDsByEmail["minh@parkgo.demo"] ?? ""
        let linhID = userIDsByEmail["linh@parkgo.demo"] ?? ""
        let baoID  = userIDsByEmail["bao@parkgo.demo"] ?? ""
        let thuID  = userIDsByEmail["thu@parkgo.demo"] ?? ""
        let namID  = userIDsByEmail["nam@parkgo.demo"] ?? ""

        func resolve(_ seedID: String) -> String {
            resolvedSeedUserID(seedID, minhID: minhID, linhID: linhID, baoID: baoID, thuID: thuID, namID: namID)
        }

        // 3. Vehicles
        let vehiclesCollection = db.collection("vehicles")
        for source in DemoSeedData.vehicles {
            let snap = try await vehiclesCollection.document(source.id ?? "").getDocumentAsync()
            guard !snap.exists else { continue }
            var vehicle = source
            vehicle.userID = resolve(source.userID)
            try await vehicleRepository.saveVehicle(vehicle)
            result.newVehicles += 1
        }

        // 4. Reviews
        let reviewsCollection = db.collection("reviews")
        for source in DemoSeedData.reviews {
            let snap = try await reviewsCollection.document(source.id ?? "").getDocumentAsync()
            guard !snap.exists else { continue }
            var review = source
            review.userID = resolve(source.userID)
            try await reviewRepository.saveReview(review)
            result.newReviews += 1
        }

        // 5. Favorites
        let favCollection = db.collection("favorites")
        for source in DemoSeedData.favorites {
            let snap = try await favCollection.document(source.id ?? "").getDocumentAsync()
            guard !snap.exists else { continue }
            var fav = source
            fav.userID = resolve(source.userID)
            try await favoriteRepository.saveFavorite(fav)
            result.newFavorites += 1
        }

        // 6. Check-ins
        let checkInsCollection = db.collection("checkins")
        for source in DemoSeedData.checkIns {
            let snap = try await checkInsCollection.document(source.id ?? "").getDocumentAsync()
            guard !snap.exists else { continue }
            var checkIn = source
            checkIn.userID = resolve(source.userID)
            try await checkInRepository.saveCheckIn(checkIn)
            result.newCheckIns += 1
        }

        // 7. Search history & parking memories (best-effort, no counter needed)
        let historyCollection = db.collection("search_history")
        for source in DemoSeedData.searchHistory {
            let snap = try await historyCollection.document(source.id ?? "").getDocumentAsync()
            guard !snap.exists else { continue }
            var h = source; h.userID = resolve(source.userID)
            try await searchHistoryRepository.saveHistory(h)
        }

        let memoriesCollection = db.collection("parking_history")
        for source in DemoSeedData.parkingMemories {
            let snap = try await memoriesCollection.document(source.id ?? "").getDocumentAsync()
            guard !snap.exists else { continue }
            var m = source; m.userID = resolve(source.userID)
            try await parkingHistoryRepository.saveMemory(m)
        }

        _ = try await authService.signIn(email: admin.email, password: admin.password)
        return result
    }

}
