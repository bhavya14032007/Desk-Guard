import SwiftUI
import Combine

@MainActor
final class MySeatViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var isTimerActive: Bool = false
    @Published var isActionLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var alertMessage: String? = nil

    private var countdownTimer: AnyCancellable?

    /// Starts or updates the client countdown based on server grace_deadline
    func updateCountdown(from deadlineString: String?) {
        let seconds = AppDateFormatter.remainingSeconds(until: deadlineString)
        self.remainingSeconds = seconds

        if seconds > 0 {
            startLocalCountdown()
        } else {
            stopLocalCountdown()
        }
    }

    private func startLocalCountdown() {
        guard countdownTimer == nil else { return }
        isTimerActive = true
        countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.stopLocalCountdown()
                }
            }
    }

    func stopLocalCountdown() {
        countdownTimer?.cancel()
        countdownTimer = nil
        isTimerActive = false
    }

    /// Step out: Call start_grace_period (20 mins)
    func stepOut(appState: AppState) async {
        isActionLoading = true
        errorMessage = nil
        do {
            let response = try await LibraryService.shared.startGracePeriod(libraryId: AppConstants.demoLibraryId)
            RealtimeService.shared.notifySeatMapChanged(libraryId: AppConstants.demoLibraryId, seatId: response.seatId)
            await appState.refreshCurrentState()
            updateCountdown(from: response.graceDeadline)
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isActionLoading = false
    }

    /// Leave library permanently: Release seat and complete visit
    func leavePermanently(appState: AppState) async {
        isActionLoading = true
        errorMessage = nil
        do {
            let response = try await LibraryService.shared.leaveLibrary(libraryId: AppConstants.demoLibraryId)
            RealtimeService.shared.notifySeatMapChanged(libraryId: AppConstants.demoLibraryId, seatId: response.seatId)
            stopLocalCountdown()
            await appState.refreshCurrentState()
            alertMessage = "Visit completed. Thank you for visiting Central Library!"
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isActionLoading = false
    }
}
