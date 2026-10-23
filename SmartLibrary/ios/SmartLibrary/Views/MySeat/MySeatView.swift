import SwiftUI

struct MySeatView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MySeatViewModel()
    @State private var showingExitAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppColors.Spacing.lg) {
                        if let error = viewModel.errorMessage {
                            ErrorBanner(
                                error: AppError(from: error),
                                retryAction: nil,
                                dismissAction: { viewModel.errorMessage = nil }
                            )
                        }

                        // State 1: User is Temporarily Away -> Display Grace Countdown
                        if appState.currentState.isAway {
                            TemporaryAwayView(viewModel: viewModel)
                                .padding(.top, AppColors.Spacing.md)
                        }
                        // State 2: User holds an Active Seat Booking
                        else if appState.currentState.hasActiveBooking {
                            activeBookingCard
                        }
                        // State 3: User is inside library but has no seat
                        else if appState.currentState.isInside {
                            EmptyStateView(
                                icon: "chair.lounge.fill",
                                title: "You're Inside Central Library",
                                message: "You have successfully scanned into the library, but haven't selected a study seat yet.",
                                buttonTitle: "Browse Available Seats"
                            ) {
                                appState.isSeatMapPresented = true
                            }
                            .padding(.top, AppColors.Spacing.xl)
                        }
                        // State 4: User is not in library
                        else {
                            EmptyStateView(
                                icon: "qrcode.viewfinder",
                                title: "Not Checked In",
                                message: "Scan the ENTRY QR code at the Central Library entrance turnstile to access seat reservations.",
                                buttonTitle: "Scan QR Code"
                            ) {
                                appState.isScannerPresented = true
                            }
                            .padding(.top, AppColors.Spacing.xl)
                        }
                    }
                    .padding(.vertical, AppColors.Spacing.md)
                }
            }
            .navigationTitle("My Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await appState.refreshCurrentState()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .alert(isPresented: $showingExitAlert) {
                Alert(
                    title: Text("Leave Library?"),
                    message: Text("This will release your seat reservation immediately for other students."),
                    primaryButton: .destructive(Text("Leave")) {
                        Task {
                            await viewModel.leavePermanently(appState: appState)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                if appState.currentState.isAway {
                    viewModel.updateCountdown(from: appState.currentState.graceDeadline)
                }
            }
            .onChange(of: appState.currentState) { newState in
                if newState.isAway {
                    viewModel.updateCountdown(from: newState.graceDeadline)
                } else {
                    viewModel.stopLocalCountdown()
                }
            }
        }
    }

    private var activeBookingCard: some View {
        VStack(spacing: AppColors.Spacing.lg) {
            // Main Seat Card
            VStack(spacing: AppColors.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Seat")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        Text(appState.currentState.seatLabel ?? "—")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                    }

                    Spacer()

                    StatusBadge(title: "Active", color: AppColors.primary, icon: "checkmark.seal.fill")
                }

                Divider()

                // Session Details
                VStack(spacing: AppColors.Spacing.sm) {
                    SessionDetailRow(
                        label: "Library",
                        value: AppConstants.libraryName,
                        icon: "building.columns.fill"
                    )
                    SessionDetailRow(
                        label: "Entered At",
                        value: AppDateFormatter.formatTime(AppDateFormatter.parseISO(appState.currentState.enteredAt)),
                        icon: "clock.fill"
                    )
                    SessionDetailRow(
                        label: "Booking Type",
                        value: "Continuous Session",
                        icon: "infinity"
                    )
                }
            }
            .padding(AppColors.Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(AppColors.CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
            .padding(.horizontal, AppColors.Spacing.lg)

            // Action Buttons
            VStack(spacing: AppColors.Spacing.md) {
                AppButton(
                    "Step Out (20 Min Grace)",
                    icon: "clock.arrow.2.circlepath",
                    style: .secondary,
                    isLoading: viewModel.isActionLoading
                ) {
                    Task {
                        await viewModel.stepOut(appState: appState)
                    }
                }

                AppButton(
                    "Leave Library Permanently",
                    icon: "arrow.right.square",
                    style: .destructive,
                    isLoading: viewModel.isActionLoading
                ) {
                    showingExitAlert = true
                }
            }
            .padding(.horizontal, AppColors.Spacing.lg)
        }
        .padding(.top, AppColors.Spacing.sm)
    }
}

private struct SessionDetailRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textMuted)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}
