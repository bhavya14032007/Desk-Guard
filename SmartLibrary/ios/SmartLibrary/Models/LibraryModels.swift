import Foundation

// MARK: - Constants
enum AppConstants {
    /// Demo Central Library UUID
    static let demoLibraryId = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    static let demoLibraryIdString = "11111111-1111-4111-8111-111111111111"
    static let libraryName = "Central Library"
    static let appName = "Smart Library"
    static let graceDurationMinutes = 20
    static let realtimeChannelTopic = "library:11111111-1111-4111-8111-111111111111"
    static let realtimeEventName = "seat-map-changed"
}

// MARK: - Seat Availability Enum
enum SeatAvailability: String, Codable, CaseIterable {
    case available = "available"
    case occupied = "occupied"
    case temporarilyAway = "temporarily_away"
    case mine = "mine"

    var title: String {
        switch self {
        case .available: return "Available"
        case .occupied: return "Occupied"
        case .temporarilyAway: return "Stepped Out"
        case .mine: return "My Seat"
        }
    }
}

// MARK: - Seat Item (Map visualization)
struct SeatItem: Identifiable, Codable, Equatable {
    let seatId: UUID
    let label: String
    let floorNumber: Int
    let zone: String
    let xPosition: Double
    let yPosition: Double
    let features: [String]
    let availabilityStatus: SeatAvailability
    let isMine: Bool
    let myBookingStatus: String?
    let graceDeadline: String?

    var id: UUID { seatId }

    enum CodingKeys: String, CodingKey {
        case seatId = "seat_id"
        case label
        case floorNumber = "floor_number"
        case zone
        case xPosition = "x_position"
        case yPosition = "y_position"
        case features
        case availabilityStatus = "availability_status"
        case isMine = "is_mine"
        case myBookingStatus = "my_booking_status"
        case graceDeadline = "grace_deadline"
    }

    var hasPower: Bool {
        features.contains("power_outlet")
    }

    var isQuietZone: Bool {
        features.contains("quiet_zone") || zone.lowercased().contains("silent")
    }

    var isBookable: Bool {
        availabilityStatus == .available
    }
}

// MARK: - User Current State
struct MyLibraryState: Codable, Equatable {
    let visitId: UUID?
    let visitStatus: String?       // "inside", "away", or nil
    let enteredAt: String?
    let bookingId: UUID?
    let seatId: UUID?
    let seatLabel: String?
    let bookingStatus: String?    // "active", "temporarily_away", or nil
    let graceDeadline: String?

    enum CodingKeys: String, CodingKey {
        case visitId = "visit_id"
        case visitStatus = "visit_status"
        case enteredAt = "entered_at"
        case bookingId = "booking_id"
        case seatId = "seat_id"
        case seatLabel = "seat_label"
        case bookingStatus = "booking_status"
        case graceDeadline = "grace_deadline"
    }

    var isInside: Bool {
        visitStatus == "inside"
    }

    var isAway: Bool {
        visitStatus == "away" || bookingStatus == "temporarily_away"
    }

    var hasActiveVisit: Bool {
        visitStatus == "inside" || visitStatus == "away"
    }

    var hasActiveBooking: Bool {
        bookingId != nil && (bookingStatus == "active" || bookingStatus == "temporarily_away")
    }
}

// MARK: - Scan Entry Result
struct ScanEntryResponse: Codable {
    let result: String // "entered", "already_inside", "returned", "grace_expired_new_visit"
}

// MARK: - Book Seat Response
struct BookSeatResponse: Codable {
    let bookingId: UUID
    let seatId: UUID
    let seatLabel: String
    let bookingStatus: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case bookingId = "booking_id"
        case seatId = "seat_id"
        case seatLabel = "seat_label"
        case bookingStatus = "booking_status"
        case createdAt = "created_at"
    }
}

// MARK: - Start Grace Response
struct StartGraceResponse: Codable {
    let bookingId: UUID
    let seatId: UUID
    let bookingStatus: String
    let graceDeadline: String

    enum CodingKeys: String, CodingKey {
        case bookingId = "booking_id"
        case seatId = "seat_id"
        case bookingStatus = "booking_status"
        case graceDeadline = "grace_deadline"
    }
}

// MARK: - Leave Library Response
struct LeaveLibraryResponse: Codable {
    let result: String
    let visitStatus: String
    let bookingStatus: String?
    let seatId: UUID?

    enum CodingKeys: String, CodingKey {
        case result
        case visitStatus = "visit_status"
        case bookingStatus = "booking_status"
        case seatId = "seat_id"
    }
}

// MARK: - Visit History Item
struct VisitHistoryItem: Identifiable, Codable {
    let visitId: UUID
    let enteredAt: String
    let exitedAt: String?
    let visitStatus: String
    let seatLabel: String?
    let seatZone: String?
    let floorNumber: Int?
    let bookingStatus: String?
    let createdAt: String?

    var id: UUID { visitId }

    enum CodingKeys: String, CodingKey {
        case visitId = "visit_id"
        case enteredAt = "entered_at"
        case exitedAt = "exited_at"
        case visitStatus = "visit_status"
        case seatLabel = "seat_label"
        case seatZone = "seat_zone"
        case floorNumber = "floor_number"
        case bookingStatus = "booking_status"
        case createdAt = "created_at"
    }
}

// MARK: - QR Payload Parser
enum QRType: String {
    case entry = "ENTRY"
    case exit = "EXIT"
}

struct QRPayload: Equatable {
    let type: QRType
    let libraryId: UUID

    /// Parses string formatted as "SLMS|ENTRY|<UUID>" or "SLMS|EXIT|<UUID>"
    static func parse(_ raw: String) -> Result<QRPayload, AppError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: "|")

        guard parts.count == 3 else {
            return .failure(.invalidQRPayload("Payload must follow format 'SLMS|ENTRY|<UUID>' or 'SLMS|EXIT|<UUID>'"))
        }

        guard parts[0] == "SLMS" else {
            return .failure(.invalidQRPayload("Header mismatch. Expected 'SLMS', got '\(parts[0])'"))
        }

        guard let qrType = QRType(rawValue: parts[1]) else {
            return .failure(.invalidQRPayload("Unknown scan action '\(parts[1])'. Expected 'ENTRY' or 'EXIT'."))
        }

        guard let uuid = UUID(uuidString: parts[2]) else {
            return .failure(.invalidQRPayload("Invalid library UUID format."))
        }

        return .success(QRPayload(type: qrType, libraryId: uuid))
    }
}
