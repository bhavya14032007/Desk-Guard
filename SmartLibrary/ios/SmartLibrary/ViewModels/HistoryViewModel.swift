import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var historyItems: [VisitHistoryItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        do {
            let items = try await LibraryService.shared.getMyHistory(libraryId: AppConstants.demoLibraryId, limit: 30)
            self.historyItems = items
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
