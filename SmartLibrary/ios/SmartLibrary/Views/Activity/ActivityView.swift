import SwiftUI

struct ActivityView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Loading Activity History...")
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                } else if let error = viewModel.errorMessage {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "Failed to Load History",
                        message: error,
                        buttonTitle: "Retry"
                    ) {
                        Task { await viewModel.loadHistory() }
                    }
                } else if viewModel.historyItems.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Activity Yet",
                        message: "Your visits and seat reservations will appear here once you check into the library."
                    )
                } else {
                    List {
                        ForEach(viewModel.historyItems) { item in
                            HistoryRow(item: item)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadHistory()
                    }
                }
            }
            .navigationTitle("Activity History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.loadHistory() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .task {
                await viewModel.loadHistory()
            }
        }
    }
}

private struct HistoryRow: View {
    let item: VisitHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppColors.Spacing.sm) {
            HStack {
                // Seat or Visit Badge
                if let label = item.seatLabel {
                    HStack(spacing: 4) {
                        Image(systemName: "chair.lounge.fill")
                            .font(.system(size: 11))
                        Text("Seat \(label)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(AppColors.primaryDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.primaryLight)
                    .cornerRadius(AppColors.CornerRadius.pill)
                } else {
                    Text("Visit Only")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.surface)
                        .cornerRadius(AppColors.CornerRadius.pill)
                }

                Spacer()

                // Status tag
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            // Location if seat reserved
            if let zone = item.seatZone {
                Text("\(zone) • Floor \(item.floorNumber ?? 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }

            // Timestamps
            HStack(spacing: AppColors.Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.right")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.seatAvailable)
                    Text(AppDateFormatter.formatDateTime(AppDateFormatter.parseISO(item.enteredAt)))
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }

                if let exit = item.exitedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.seatOccupied)
                        Text(AppDateFormatter.formatTime(AppDateFormatter.parseISO(exit)))
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(AppColors.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppColors.CornerRadius.md)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private var statusText: String {
        if item.visitStatus == "inside" {
            return "Active Now"
        }
        if item.visitStatus == "away" {
            return "Stepped Out"
        }
        if let bookingStatus = item.bookingStatus {
            switch bookingStatus {
            case "expired": return "Grace Expired"
            case "completed": return "Completed"
            case "cancelled": return "Cancelled"
            default: return bookingStatus.capitalized
            }
        }
        return "Completed"
    }

    private var statusColor: Color {
        if item.visitStatus == "inside" {
            return AppColors.seatAvailable
        }
        if item.visitStatus == "away" {
            return AppColors.seatAway
        }
        if item.bookingStatus == "expired" {
            return AppColors.seatOccupied
        }
        return AppColors.textSecondary
    }
}
