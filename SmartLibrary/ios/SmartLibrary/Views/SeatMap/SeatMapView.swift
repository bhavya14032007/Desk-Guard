import SwiftUI

struct SeatMapView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SeatMapViewModel()
    @State private var showingDetailSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Controls: Floor Switcher & Feature Filters
                    VStack(spacing: AppColors.Spacing.sm) {
                        // Floor Picker
                        Picker("Select Floor", selection: $viewModel.selectedFloor) {
                            Text("Floor 1 (Main Hall)").tag(1)
                            Text("Floor 2 (Silent Study)").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.selectedFloor) { _ in
                            viewModel.calculateRecommendation()
                        }

                        // Filter Chips
                        HStack(spacing: AppColors.Spacing.sm) {
                            FilterChip(
                                title: "Quiet Zone",
                                icon: "speaker.slash.fill",
                                isSelected: $viewModel.filterQuietZoneOnly
                            ) {
                                viewModel.calculateRecommendation()
                            }

                            FilterChip(
                                title: "Power Outlet",
                                icon: "bolt.fill",
                                isSelected: $viewModel.filterPowerOnly
                            ) {
                                viewModel.calculateRecommendation()
                            }

                            Spacer()

                            // Available seats badge
                            Text("\(viewModel.availableCountOnFloor) Available")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.primaryLight)
                                .cornerRadius(AppColors.CornerRadius.pill)
                        }
                    }
                    .padding(.horizontal, AppColors.Spacing.md)
                    .padding(.vertical, AppColors.Spacing.sm)
                    .background(AppColors.cardBackground)
                    .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)

                    // Status Legend
                    HStack(spacing: AppColors.Spacing.md) {
                        LegendItem(color: AppColors.seatAvailable, label: "Available")
                        LegendItem(color: AppColors.seatOccupied, label: "Occupied")
                        LegendItem(color: AppColors.seatAway, label: "Away")
                        LegendItem(color: AppColors.seatMine, label: "My Seat")
                    }
                    .padding(.vertical, AppColors.Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.surface)

                    // Seat Layout View / Error / Loading States
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading Floor Plan...")
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        EmptyStateView(
                            icon: "wifi.exclamationmark",
                            title: "Failed to Load Seat Map",
                            message: error,
                            buttonTitle: "Retry"
                        ) {
                            Task { await viewModel.loadSeats() }
                        }
                        Spacer()
                    } else if viewModel.displayedSeats.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "chair.lounge",
                            title: "No Matching Seats",
                            message: "Try clearing your filters to see more seats on Floor \(viewModel.selectedFloor).",
                            buttonTitle: "Reset Filters"
                        ) {
                            viewModel.filterQuietZoneOnly = false
                            viewModel.filterPowerOnly = false
                        }
                        Spacer()
                    } else if viewModel.availableCountOnFloor == 0 {
                        VStack(spacing: AppColors.Spacing.md) {
                            HStack(spacing: AppColors.Spacing.xs) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(AppColors.seatAway)
                                Text("No seats available right now. Please check again shortly.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .padding(AppColors.Spacing.sm)
                            .background(AppColors.seatAway.opacity(0.12))
                            .cornerRadius(AppColors.CornerRadius.md)
                            .padding(.horizontal, AppColors.Spacing.md)
                            .padding(.top, AppColors.Spacing.sm)

                            seatPlanScrollView
                        }
                    } else {
                        seatPlanScrollView
                    }
                }
            }
            .navigationTitle("Central Library Seats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.loadSeats() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(item: $viewModel.selectedSeat) { seat in
                SeatDetailSheet(
                    seat: seat,
                    isRecommended: viewModel.recommendedSeat?.seatId == seat.seatId,
                    viewModel: viewModel
                )
                .presentationDetents([.medium, .fraction(0.55)])
            }
            .task {
                await viewModel.loadSeats()
            }
            .refreshable {
                await viewModel.loadSeats()
            }
        }
    }

    private var seatPlanScrollView: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(alignment: .leading, spacing: AppColors.Spacing.lg) {
                // Zone Title Header
                let zones = Array(Set(viewModel.displayedSeats.map { $0.zone })).sorted()
                ForEach(zones, id: \.self) { zone in
                    VStack(alignment: .leading, spacing: AppColors.Spacing.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(AppColors.primary)
                            Text(zone)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.leading, AppColors.Spacing.sm)

                        // Seats Grid for this zone
                        let zoneSeats = viewModel.displayedSeats.filter { $0.zone == zone }
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.fixed(52), spacing: 12), count: 6),
                            spacing: 12
                        ) {
                            ForEach(zoneSeats) { seat in
                                SeatCardView(
                                    seat: seat,
                                    isRecommended: viewModel.recommendedSeat?.seatId == seat.seatId,
                                    isSelected: viewModel.selectedSeat?.seatId == seat.seatId
                                ) {
                                    viewModel.selectedSeat = seat
                                }
                            }
                        }
                        .padding(AppColors.Spacing.md)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppColors.CornerRadius.lg)
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    }
                }
            }
            .padding(AppColors.Spacing.md)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let icon: String
    @Binding var isSelected: Bool
    let onChange: () -> Void

    var body: some View {
        Button {
            isSelected.toggle()
            onChange()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? AppColors.primary : AppColors.surface)
            .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            .cornerRadius(AppColors.CornerRadius.pill)
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

#Preview {
    let state = AppState()
    state.enableDemoMode()
    return SeatMapView()
        .environmentObject(state)
}
