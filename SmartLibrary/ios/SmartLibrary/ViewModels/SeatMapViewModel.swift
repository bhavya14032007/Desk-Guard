import SwiftUI

@MainActor
final class SeatMapViewModel: ObservableObject {
    @Published var allSeats: [SeatItem] = []
    @Published var selectedFloor: Int = 1
    @Published var filterQuietZoneOnly: Bool = false
    @Published var filterPowerOnly: Bool = false
    @Published var selectedSeat: SeatItem? = nil
    @Published var recommendedSeat: SeatItem? = nil
    @Published var isLoading: Bool = false
    @Published var isBooking: Bool = false
    @Published var errorMessage: String? = nil
    @Published var bookingSuccessAlert: String? = nil

    /// Filtered seats for current floor & toggled amenities
    var displayedSeats: [SeatItem] {
        allSeats.filter { seat in
            guard seat.floorNumber == selectedFloor else { return false }
            if filterQuietZoneOnly && !seat.isQuietZone { return false }
            if filterPowerOnly && !seat.hasPower { return false }
            return true
        }
    }

    /// Count of currently available seats across the current view
    var availableCountOnFloor: Int {
        displayedSeats.filter { $0.availabilityStatus == .available }.count
    }

    /// Load seats from database
    func loadSeats() async {
        isLoading = true
        errorMessage = nil
        do {
            let seats = try await LibraryService.shared.getSeatMap(libraryId: AppConstants.demoLibraryId)
            self.allSeats = seats
            calculateRecommendation()
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Rule-based recommendation engine:
    /// Suggests best seat matching user filters with maximum amenities
    func calculateRecommendation() {
        let candidates = displayedSeats.filter { $0.availabilityStatus == .available }
        guard !candidates.isEmpty else {
            self.recommendedSeat = nil
            return
        }

        // Rank by matching filters + amenities count
        let best = candidates.max { a, b in
            var scoreA = 0
            var scoreB = 0

            if a.hasPower { scoreA += 2 }
            if b.hasPower { scoreB += 2 }
            if a.isQuietZone { scoreA += 2 }
            if b.isQuietZone { scoreB += 2 }
            scoreA += a.features.count
            scoreB += b.features.count

            return scoreA < scoreB
        }

        self.recommendedSeat = best
    }

    /// Book selected seat
    func confirmBooking(seat: SeatItem, appState: AppState) async -> Bool {
        isBooking = true
        errorMessage = nil
        do {
            let response = try await LibraryService.shared.bookSeat(seatId: seat.seatId)
            // Broadcast realtime change to other clients
            RealtimeService.shared.notifySeatMapChanged(libraryId: AppConstants.demoLibraryId, seatId: seat.seatId)
            await appState.refreshCurrentState()
            await loadSeats()
            bookingSuccessAlert = "Successfully reserved seat \(response.seatLabel)!"
            isBooking = false
            return true
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
            isBooking = false
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            isBooking = false
            return false
        }
    }
}
