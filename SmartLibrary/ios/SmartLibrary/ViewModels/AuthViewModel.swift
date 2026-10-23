import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isSignUp: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func authenticate(appState: AppState) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if isSignUp {
                let user = try await AuthService.shared.signUp(email: trimmedEmail, password: password)
                appState.currentUser = user
                appState.isAuthenticated = true
            } else {
                let user = try await AuthService.shared.signIn(email: trimmedEmail, password: password)
                appState.currentUser = user
                appState.isAuthenticated = true
            }
            await appState.refreshCurrentState()
            RealtimeService.shared.subscribeToSeatChanges()
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
