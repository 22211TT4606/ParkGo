import Foundation
import UserNotifications

final class PushNotificationService {
    func requestAuthorization() async throws {
        _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    // Hook point for Firebase Messaging token registration if the demo later needs push alerts.
    func registerForRemoteNotifications() {}
}
