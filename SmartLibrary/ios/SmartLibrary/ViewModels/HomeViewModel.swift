import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var availableSeatsCount: Int = 0
    @Published var totalSeatsCount: Int = 0
    @Published var isLoadingSeats: Bool = false
    @Published var errorMessage: String? = nil

    func loadSeatSummary() async {
        isLoadingSeats = true
        errorMessage = nil
        do {
            let seats = try await LibraryService.shared.getSeatMap(libraryId: AppConstants.demoLibraryId)
            self.totalSeatsCount = seats.count
            self.availableSeatsCount = seats.filter { $0.availabilityStatus == .available }.count
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoadingSeats = false
    }
}
