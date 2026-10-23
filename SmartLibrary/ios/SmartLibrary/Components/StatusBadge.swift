import SwiftUI

struct StatusBadge: View {
    let title: String
    let color: Color
    let icon: String?

    init(title: String, color: Color, icon: String? = nil) {
        self.title = title
        self.color = color
        self.icon = icon
    }

    init(for availability: SeatAvailability) {
        self.title = availability.title
        switch availability {
        case .available:
            self.color = AppColors.seatAvailable
            self.icon = "checkmark.circle.fill"
        case .occupied:
            self.color = AppColors.seatOccupied
            self.icon = "xmark.circle.fill"
        case .temporarilyAway:
            self.color = AppColors.seatAway
            self.icon = "clock.fill"
        case .mine:
            self.color = AppColors.seatMine
            self.icon = "person.fill"
        }
    }

    var body: some View {
        HStack(spacing: AppColors.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, AppColors.Spacing.sm)
        .padding(.vertical, AppColors.Spacing.xs)
        .background(color.opacity(0.12))
        .cornerRadius(AppColors.CornerRadius.pill)
    }
}
