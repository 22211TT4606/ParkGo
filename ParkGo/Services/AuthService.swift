import Foundation
import FirebaseAuth
import FirebaseCore

final class AuthService {
    var isAvailable: Bool { FirebaseBootstrapper.isConfigured }

    var currentUserID: String? {
        guard isAvailable else { return nil }
        return Auth.auth().currentUser?.uid
    }

    func observeAuthState(_ onChange: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle? {
        guard isAvailable else {
            onChange(nil)
            return nil
        }
        return Auth.auth().addStateDidChangeListener { _, user in
            onChange(user)
        }
    }

    func removeListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }

    func signIn(email: String, password: String) async throws -> String {
        guard isAvailable else { throw AuthError.firebaseNotConfigured }
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func register(email: String, password: String) async throws -> String {
        guard isAvailable else { throw AuthError.firebaseNotConfigured }
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    /// Tạo tài khoản mới mà không đăng xuất admin hiện tại, bằng cách dùng secondary FirebaseApp.
    func adminCreateUser(email: String, password: String) async throws -> String {
        guard isAvailable else { throw AuthError.firebaseNotConfigured }
        guard let options = FirebaseApp.app()?.options else { throw AuthError.firebaseNotConfigured }

        let appName = "adminCreate_\(UUID().uuidString)"
        FirebaseApp.configure(name: appName, options: options)

        guard let secondaryApp = FirebaseApp.app(name: appName) else {
            throw AuthError.firebaseNotConfigured
        }

        do {
            let auth = Auth.auth(app: secondaryApp)
            let result = try await auth.createUser(withEmail: email, password: password)
            let uid = result.user.uid
            _ = await secondaryApp.delete()
            return uid
        } catch {
            _ = await secondaryApp.delete()
            throw error
        }
    }

    func changePassword(email: String, currentPassword: String, newPassword: String) async throws {
        guard isAvailable else { throw AuthError.firebaseNotConfigured }
        guard let user = Auth.auth().currentUser else { throw AuthError.firebaseNotConfigured }
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: newPassword)
    }

    func signOut() throws {
        guard isAvailable else { return }
        try Auth.auth().signOut()
    }

    enum AuthError: LocalizedError {
        case firebaseNotConfigured

        var errorDescription: String? {
            switch self {
            case .firebaseNotConfigured:
                return "Firebase chưa được cấu hình. Kiểm tra GoogleService-Info.plist và chạy lại xcodegen generate."
            }
        }
    }
}

