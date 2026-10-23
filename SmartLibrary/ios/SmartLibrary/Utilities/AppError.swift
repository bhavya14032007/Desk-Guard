import Foundation

/// Centralized application error handling and human-friendly translations
enum AppError: LocalizedError, Equatable {
    case unauthorized
    case invalidLibrary
    case invalidSeat
    case seatDisabled
    case noActiveVisit
    case notInsideLibrary
    case seatUnavailable
    case alreadyHasSeat
    case noActiveBooking
    case gracePeriodExpired
    case invalidQRPayload(String)
    case missingConfiguration(String)
    case networkError(String)
    case unknown(String)

    init(from message: String) {
        let upper = message.uppercased()
        if upper.contains("UNAUTHORIZED") {
            self = .unauthorized
        } else if upper.contains("INVALID_LIBRARY") {
            self = .invalidLibrary
        } else if upper.contains("INVALID_SEAT") {
            self = .invalidSeat
        } else if upper.contains("SEAT_DISABLED") {
            self = .seatDisabled
        } else if upper.contains("NO_ACTIVE_VISIT") {
            self = .noActiveVisit
        } else if upper.contains("NOT_INSIDE_LIBRARY") {
            self = .notInsideLibrary
        } else if upper.contains("SEAT_UNAVAILABLE") {
            self = .seatUnavailable
        } else if upper.contains("ALREADY_HAS_SEAT") {
            self = .alreadyHasSeat
        } else if upper.contains("NO_ACTIVE_BOOKING") {
            self = .noActiveBooking
        } else if upper.contains("GRACE_PERIOD_EXPIRED") {
            self = .gracePeriodExpired
        } else {
            self = .unknown(message)
        }
    }

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to access library services."
        case .invalidLibrary:
            return "Unrecognized library QR code. Please scan a valid Central Library QR code."
        case .invalidSeat:
            return "The selected seat could not be found."
        case .seatDisabled:
            return "This seat is currently undergoing maintenance and cannot be reserved."
        case .noActiveVisit:
            return "You must scan the library ENTRY QR code before you can reserve a seat."
        case .notInsideLibrary:
            return "You are currently marked as stepped out. Scan the ENTRY QR code to resume your visit."
        case .seatUnavailable:
            return "This seat was just reserved by another student. Please pick another seat."
        case .alreadyHasSeat:
            return "You already hold an active seat reservation. Release it first before choosing another."
        case .noActiveBooking:
            return "You do not have an active seat reservation."
        case .gracePeriodExpired:
            return "Your 20-minute temporary away grace period has expired. Your seat was released."
        case .invalidQRPayload(let reason):
            return "Invalid QR code format: \(reason)"
        case .missingConfiguration(let detail):
            return "Configuration missing: \(detail). Check Config.xcconfig."
        case .networkError(let detail):
            return "Network connection issue: \(detail)"
        case .unknown(let detail):
            return "An unexpected error occurred: \(detail)"
        }
    }
}
