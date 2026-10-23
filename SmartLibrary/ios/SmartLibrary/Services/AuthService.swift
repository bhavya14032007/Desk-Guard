import Foundation
import Supabase

/// Manages Supabase Auth lifecycle: Sign up, Sign in, Sign out, and Session restoration
final class AuthService {
    static let shared = AuthService()
    private let client = SupabaseManager.shared.client

    private init() {}

    /// Current authenticated user
    var currentUser: User? {
        client.auth.currentUser
    }

    /// Sign up with email and password
    func signUp(email: String, password: String) async throws -> User {
        guard SupabaseManager.shared.isConfigured else {
            throw AppError.missingConfiguration(SupabaseManager.shared.configurationDiagnostic ?? "")
        }
        let authResponse = try await client.auth.signUp(email: email, password: password)
        return authResponse.user
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> User {
        guard SupabaseManager.shared.isConfigured else {
            throw AppError.missingConfiguration(SupabaseManager.shared.configurationDiagnostic ?? "")
        }
        let session = try await client.auth.signIn(email: email, password: password)
        return session.user
    }

    /// Sign out current user
    func signOut() async throws {
        guard SupabaseManager.shared.isConfigured else { return }
        try await client.auth.signOut()
    }

    /// Restores existing session from local secure storage
    func restoreSession() async -> User? {
        guard SupabaseManager.shared.isConfigured else { return nil }
        do {
            let session = try await client.auth.session
            return session.user
        } catch {
            return nil
        }
    }
}
