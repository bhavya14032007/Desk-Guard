import Foundation
import Supabase
import Combine

/// Realtime notification manager supporting Supabase Broadcast channel
/// with an automatic 8-second polling fallback.
final class RealtimeService: ObservableObject {
    static let shared = RealtimeService()

    @Published var shouldRefreshSeatMap: Bool = false
    private let client = SupabaseManager.shared.client
    private var channel: RealtimeChannelV2?
    private var pollingTimer: AnyCancellable?
    private var isSubscribed = false

    private init() {}

    /// Subscribes to the library's Realtime Broadcast channel
    func subscribeToSeatChanges(libraryId: UUID = AppConstants.demoLibraryId) {
        guard SupabaseManager.shared.isConfigured else {
            startPollingFallback()
            return
        }

        if isSubscribed { return }

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let channelName = "library:\(libraryId.uuidString.lowercased())"
                let channel = self.client.channel(channelName)
                self.channel = channel

                // Listen for 'seat-map-changed' broadcast events
                await channel.onBroadcast(event: AppConstants.realtimeEventName) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.shouldRefreshSeatMap = true
                    }
                }

                await channel.subscribe()
                self.isSubscribed = true
            } catch {
                // If realtime broadcast fails, ensure polling is active
                DispatchQueue.main.async {
                    self.startPollingFallback()
                }
            }
        }

        // Always activate backup polling to guarantee freshness even across network hiccups
        startPollingFallback()
    }

    /// Broadcasts an event to notify other clients when a booking or release occurs
    func notifySeatMapChanged(libraryId: UUID = AppConstants.demoLibraryId, seatId: UUID? = nil) {
        Task { [weak self] in
            guard let self = self, let channel = self.channel else { return }
            do {
                struct BroadcastPayload: Encodable {
                    let library_id: String
                    let seat_id: String?
                    let timestamp: String
                }

                let payload = BroadcastPayload(
                    library_id: libraryId.uuidString.lowercased(),
                    seat_id: seatId?.uuidString.lowercased(),
                    timestamp: ISO8601DateFormatter().string(from: Date())
                )

                try await channel.broadcast(event: AppConstants.realtimeEventName, message: payload)
            } catch {
                // Ignore broadcast error; fallback polling covers all devices
            }
        }
    }

    /// Polling fallback timer (every 8 seconds)
    func startPollingFallback() {
        guard pollingTimer == nil else { return }
        pollingTimer = Timer.publish(every: 8.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.shouldRefreshSeatMap = true
            }
    }

    /// Stop polling when not on seat map
    func stopPollingFallback() {
        pollingTimer?.cancel()
        pollingTimer = nil
    }

    /// Unsubscribe cleanup
    func unsubscribe() {
        stopPollingFallback()
        if let channel = channel {
            Task {
                await channel.unsubscribe()
            }
        }
        self.channel = nil
        self.isSubscribed = false
    }
}
