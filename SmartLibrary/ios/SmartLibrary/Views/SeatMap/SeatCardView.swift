import SwiftUI

struct SeatCardView: View {
    let seat: SeatItem
    let isRecommended: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Top status or amenity icon
                HStack(spacing: 2) {
                    if isRecommended {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.yellow)
                    } else if seat.hasPower {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(textColor.opacity(0.8))
                    }

                    if seat.isQuietZone {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 8))
                            .foregroundColor(textColor.opacity(0.8))
                    }
                }
                .frame(height: 10)

                // Seat Label
                Text(seat.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(textColor)

                // Subtitle/Status dot
                Circle()
                    .fill(dotColor)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 48, height: 48)
            .background(bgColor)
            .cornerRadius(AppColors.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppColors.CornerRadius.sm)
                    .stroke(borderColor, lineWidth: isSelected || isRecommended ? 2 : 1)
            )
            .shadow(color: isSelected ? AppColors.primary.opacity(0.3) : Color.black.opacity(0.04), radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var bgColor: Color {
        switch seat.availabilityStatus {
        case .available:
            return isSelected ? AppColors.seatAvailable.opacity(0.2) : Color.white
        case .occupied:
            return AppColors.seatOccupied.opacity(0.12)
        case .temporarilyAway:
            return AppColors.seatAway.opacity(0.15)
        case .mine:
            return AppColors.seatMine.opacity(0.18)
        }
    }

    private var textColor: Color {
        switch seat.availabilityStatus {
        case .available:
            return AppColors.textPrimary
        case .occupied:
            return AppColors.seatOccupied
        case .temporarilyAway:
            return AppColors.seatAway
        case .mine:
            return AppColors.seatMine
        }
    }

    private var dotColor: Color {
        switch seat.availabilityStatus {
        case .available:
            return AppColors.seatAvailable
        case .occupied:
            return AppColors.seatOccupied
        case .temporarilyAway:
            return AppColors.seatAway
        case .mine:
            return AppColors.seatMine
        }
    }

    private var borderColor: Color {
        if isSelected {
            return AppColors.primary
        }
        if isRecommended {
            return Color.orange
        }
        switch seat.availabilityStatus {
        case .available:
            return AppColors.border
        case .occupied:
            return AppColors.seatOccupied.opacity(0.4)
        case .temporarilyAway:
            return AppColors.seatAway.opacity(0.5)
        case .mine:
            return AppColors.seatMine
        }
    }
}
