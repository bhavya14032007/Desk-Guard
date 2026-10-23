import SwiftUI
import Combine
import Supabase

enum AppTab: Hashable {
    case home
    case mySeat
    case activity
}

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var currentState: MyLibraryState = MyLibraryState(
        visitId: nil,
        visitStatus: nil,
        enteredAt: nil,
        bookingId: nil,
        seatId: nil,
        seatLabel: nil,
        bookingStatus: nil,
        graceDeadline: nil
    )
    @Published var activeTab: AppTab = .home
    @Published var isScannerPresented: Bool = false
    @Published var isSeatMapPresented: Bool = false
    @Published var isExitChoicePresented: Bool = false
    @Published var globalError: AppError? = nil
    @Published var isStateLoading: Bool = false
    @Published var isDemoMode: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe realtime broadcasts to refresh state
        RealtimeService.shared.$shouldRefreshSeatMap
            .filter { $0 }
            .sink { [weak self] _ in
                Task {
                    await self?.refreshCurrentState()
                    RealtimeService.shared.shouldRefreshSeatMap = false
                }
            }
            .store(in: &cancellables)
    }

    /// Checks if a valid session exists on app launch
    func checkSession() async {
        isStateLoading = true
        if let user = await AuthService.shared.restoreSession() {
            self.currentUser = user
            self.isAuthenticated = true
            await refreshCurrentState()
            RealtimeService.shared.subscribeToSeatChanges()
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
        }
        isStateLoading = false
    }

    /// Enables instant demo mode for hackathon testing without authentication friction
    func enableDemoMode() {
        self.isDemoMode = true
        self.isAuthenticated = true
        self.currentState = MyLibraryState(
            visitId: UUID(),
            visitStatus: "inside",
            enteredAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800)),
            bookingId: UUID(),
            seatId: UUID(),
            seatLabel: "A1",
            bookingStatus: "active",
            graceDeadline: nil
        )
        Task {
            await self.refreshCurrentState()
            RealtimeService.shared.subscribeToSeatChanges()
        }
    }

    /// Refreshes user's active visit and booking status
    func refreshCurrentState() async {
        guard isAuthenticated && !isDemoMode else { return }
        do {
            let state = try await LibraryService.shared.getMyState(libraryId: AppConstants.demoLibraryId)
            self.currentState = state
        } catch let err as AppError {
            self.globalError = err
        } catch {
            self.globalError = AppError.unknown(error.localizedDescription)
        }
    }

    /// Sign out
    func signOut() async {
        isDemoMode = false
        do {
            try await AuthService.shared.signOut()
            self.isAuthenticated = false
            self.currentUser = nil
            self.currentState = MyLibraryState(
                visitId: nil,
                visitStatus: nil,
                enteredAt: nil,
                bookingId: nil,
                seatId: nil,
                seatLabel: nil,
                bookingStatus: nil,
                graceDeadline: nil
            )
            RealtimeService.shared.unsubscribe()
        } catch {
            self.globalError = AppError(from: error.localizedDescription)
        }
    }
}
