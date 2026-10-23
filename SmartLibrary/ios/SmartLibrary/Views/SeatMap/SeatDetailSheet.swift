import SwiftUI

struct SeatDetailSheet: View {
    let seat: SeatItem
    let isRecommended: Bool
    @ObservedObject var viewModel: SeatMapViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppColors.Spacing.lg) {
            // Header Handle
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 4)
                .padding(.top, AppColors.Spacing.sm)

            // Header info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: AppColors.Spacing.sm) {
                        Text("Seat \(seat.label)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)

                        if isRecommended {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                Text("Best Match")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(AppColors.CornerRadius.pill)
                        }
                    }

                    Text("Floor \(seat.floorNumber) • \(seat.zone)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                StatusBadge(for: seat.availabilityStatus)
            }
            .padding(.horizontal, AppColors.Spacing.lg)

            Divider()

            // Seat Amenities & Features
            VStack(alignment: .leading, spacing: AppColors.Spacing.sm) {
                Text("Seat Amenities")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppColors.Spacing.sm) {
                    AmenityRow(
                        icon: "bolt.fill",
                        title: "Power Outlet",
                        isAvailable: seat.hasPower
                    )
                    AmenityRow(
                        icon: "speaker.slash.fill",
                        title: "Quiet Zone",
                        isAvailable: seat.isQuietZone
                    )
                    AmenityRow(
                        icon: "sun.max.fill",
                        title: "Window View",
                        isAvailable: seat.features.contains("window_view")
                    )
                    AmenityRow(
                        icon: "figure.stand",
                        title: "Standing Desk",
                        isAvailable: seat.features.contains("standing_desk")
                    )
                }
            }
            .padding(.horizontal, AppColors.Spacing.lg)

            // Grace period note if stepped out
            if seat.availabilityStatus == .temporarilyAway, let deadline = seat.graceDeadline {
                HStack(spacing: AppColors.Spacing.sm) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppColors.seatAway)
                    Text("Occupant stepped out. Reserved until \(AppDateFormatter.formatTime(AppDateFormatter.parseISO(deadline)))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(AppColors.Spacing.md)
                .background(AppColors.seatAway.opacity(0.1))
                .cornerRadius(AppColors.CornerRadius.md)
                .padding(.horizontal, AppColors.Spacing.lg)
            }

            Spacer()

            // Error display if booking failed
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.seatOccupied)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppColors.Spacing.lg)
            }

            // Booking Action Button
            if seat.isBookable {
                AppButton(
                    "Reserve Seat \(seat.label)",
                    icon: "checkmark.circle.fill",
                    isLoading: viewModel.isBooking
                ) {
                    Task {
                        let success = await viewModel.confirmBooking(seat: seat, appState: appState)
                        if success {
                            dismiss()
                            appState.activeTab = .mySeat
                        }
                    }
                }
                .padding(.horizontal, AppColors.Spacing.lg)
                .padding(.bottom, AppColors.Spacing.lg)
            } else if seat.isMine {
                AppButton("View in My Seat", icon: "person.fill", style: .secondary) {
                    dismiss()
                    appState.activeTab = .mySeat
                }
                .padding(.horizontal, AppColors.Spacing.lg)
                .padding(.bottom, AppColors.Spacing.lg)
            } else {
                Text("This seat is currently unavailable.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.bottom, AppColors.Spacing.lg)
            }
        }
    }
}

private struct AmenityRow: View {
    let icon: String
    let title: String
    let isAvailable: Bool

    var body: some View {
        HStack(spacing: AppColors.Spacing.xs) {
            Image(systemName: isAvailable ? icon : "xmark.circle")
                .foregroundColor(isAvailable ? AppColors.primary : AppColors.textMuted)
                .font(.system(size: 14))
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(isAvailable ? AppColors.textPrimary : AppColors.textMuted)
            Spacer()
        }
        .padding(AppColors.Spacing.sm)
        .background(isAvailable ? AppColors.primaryLight.opacity(0.3) : AppColors.surface)
        .cornerRadius(AppColors.CornerRadius.sm)
    }
}
