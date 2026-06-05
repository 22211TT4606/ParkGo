import Foundation
import FirebaseCore

enum FirebaseBootstrapper {
    static private(set) var isConfigured = false

    static func configure() {
        guard FirebaseApp.app() == nil else {
            isConfigured = true
            return
        }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("[ParkGo] GoogleService-Info.plist not found in bundle. Firebase skipped.")
            print("[ParkGo] Run `xcodegen generate` after placing the plist in the repo root.")
            return
        }
        FirebaseApp.configure()
        isConfigured = FirebaseApp.app() != nil
        if !isConfigured {
            print("[ParkGo] FirebaseApp.configure() called but app instance is nil.")
        }
    }
}
