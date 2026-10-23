import Foundation
import Supabase

/// Service for executing PostgreSQL RPC operations for Smart Library
final class LibraryService {
    static let shared = LibraryService()
    private let client = SupabaseManager.shared.client

    private init() {}

    private func ensureConfigured() throws {
        guard SupabaseManager.shared.isConfigured else {
            throw AppError.missingConfiguration(SupabaseManager.shared.configurationDiagnostic ?? "Supabase not configured")
        }
    }

    /// Fetches the interactive seat map with realtime availability for the library
    func getSeatMap(libraryId: UUID = AppConstants.demoLibraryId) async throws -> [SeatItem] {
        try ensureConfigured()
        struct Params: Encodable {
            let p_library_id: String
        }

        do {
            let response: [SeatItem] = try await client
                .rpc("get_seat_map", params: Params(p_library_id: libraryId.uuidString.lowercased()))
                .execute()
                .value
            return response
        } catch {
            throw mapError(error)
        }
    }

    /// Fetches current user's active visit and booking state
    func getMyState(libraryId: UUID = AppConstants.demoLibraryId) async throws -> MyLibraryState {
        try ensureConfigured()
        struct Params: Encodable {
            let p_library_id: String
        }

        do {
            let state: MyLibraryState = try await client
                .rpc("get_my_state", params: Params(p_library_id: libraryId.uuidString.lowercased()))
                .execute()
                .value
            return state
        } catch {
            throw mapError(error)
        }
    }

    /// Records ENTRY QR scan: creates visit, restores grace booking, or detects duplicate
    func scanEntry(libraryId: UUID) async throws -> ScanEntryResponse {
        try ensureConfigured()
        struct Params: Encodable {
            let p_library_id: String
        }

        do {
            let result: ScanEntryResponse = try await client
                .rpc("scan_entry", params: Params(p_library_id: libraryId.uuidString.lowercased()))
                .execute()
                .value
            return result
        } catch {
            throw mapError(error)
        }
    }

    /// Atomically reserves a seat for the current user
    func bookSeat(seatId: UUID) async throws -> BookSeatResponse {
        try ensureConfigured()
        struct Params: Encodable {
            let p_seat_id: String
        }

        do {
            let result: BookSeatResponse = try await client
                .rpc("book_seat", params: Params(p_seat_id: seatId.uuidString.lowercased()))
                .execute()
                .value
            return result
        } catch {
            throw mapError(error)
        }
    }

    /// Starts 20-minute temporary-away grace period
    func startGracePeriod(libraryId: UUID = AppConstants.demoLibraryId) async throws -> StartGraceResponse {
        try ensureConfigured()
        struct Params: Encodable {
            let p_library_id: String
        }

        do {
            let result: StartGraceResponse = try await client
                .rpc("start_grace_period", params: Params(p_library_id: libraryId.uuidString.lowercased()))
                .execute()
                .value
            return result
        } catch {
            throw mapError(error)
        }
    }

    /// Records permanent exit: marks visit completed and releases seat immediately
    func leaveLibrary(libraryId: UUID = AppConstants.demoLibraryId) async throws -> LeaveLibraryResponse {
        try ensureConfigured()
        struct Params: Encodable {
            let p_library_id: String
        }

        do {
            let result: LeaveLibraryResponse = try await client
                .rpc("leave_library", params: Params(p_library_id: libraryId.uuidString.lowercased()))
                .execute()
                .value
            return result
        } catch {
            throw mapError(error)
        }
    }

    /// Fetches sanitized visit and booking history for the user
    func getMyHistory(libraryId: UUID = AppConstants.demoLibraryId, limit: Int = 30) async throws -> [VisitHistoryItem] {
        try ensureConfigured()
        struct Params: Encodable {
            let p_library_id: String
            let p_limit: Int
        }

        do {
            let history: [VisitHistoryItem] = try await client
                .rpc("get_my_history", params: Params(p_library_id: libraryId.uuidString.lowercased(), p_limit: limit))
                .execute()
                .value
            return history
        } catch {
            throw mapError(error)
        }
    }

    // MARK: - Error Mapping
    private func mapError(_ error: Error) -> AppError {
        let desc = error.localizedDescription
        return AppError(from: desc)
    }
}
