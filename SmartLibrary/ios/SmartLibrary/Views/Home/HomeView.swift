import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppColors.Spacing.lg) {
                        // Header with Library Name & Sign Out
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(AppConstants.appName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppColors.primaryDark)
                                    .textCase(.uppercase)
                                    .tracking(1)

                                Text(AppConstants.libraryName)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                            }

                            Spacer()

                            Button {
                                Task {
                                    await appState.signOut()
                                }
                            } label: {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(AppColors.Spacing.sm)
                                    .background(AppColors.surface)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, AppColors.Spacing.lg)
                        .padding(.top, AppColors.Spacing.sm)

                        // Visit & Reservation Status Banner
                        statusBannerCard

                        // ========================================================
                        // PRIMARY ACTION: PROMINENT LARGE GREEN SCAN QR CODE BUTTON
                        // ========================================================
                        Button {
                            appState.isScannerPresented = true
                        } label: {
                            HStack(spacing: AppColors.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Scan QR Code")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)

                                    Text(scanSubtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.white.opacity(0.9))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(AppColors.Spacing.md)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppColors.primary, AppColors.primaryDark]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(AppColors.CornerRadius.lg)
                            .shadow(color: AppColors.primary.opacity(0.35), radius: 10, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, AppColors.Spacing.lg)

                        // Compact Available-Seat Count Card
                        seatAvailabilityCard

                        // Interactive Seat Map Quick Entry Card
                        interactiveMapCard

                        // Quick Guide & Security Limitations
                        hackathonNoticeCard
                    }
                    .padding(.bottom, AppColors.Spacing.xl)
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadSeatSummary()
                await appState.refreshCurrentState()
            }
            .refreshable {
                await viewModel.loadSeatSummary()
                await appState.refreshCurrentState()
            }
        }
    }

    // MARK: - Visit Status Banner
    private var statusBannerCard: some View {
        HStack(spacing: AppColors.Spacing.md) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: statusIcon)
                    .font(.system(size: 20))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text(statusDescription)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            if appState.currentState.hasActiveBooking {
                Button {
                    appState.activeTab = .mySeat
                } label: {
                    Text("View")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.primaryLight)
                        .cornerRadius(AppColors.CornerRadius.pill)
                }
            }
        }
        .padding(AppColors.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppColors.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppColors.CornerRadius.md)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .padding(.horizontal, AppColors.Spacing.lg)
    }

    // MARK: - Seat Availability Card
    private var seatAvailabilityCard: some View {
        VStack(spacing: AppColors.Spacing.sm) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColors.seatAvailable)
                        .frame(width: 8, height: 8)
                    Text("Live Library Capacity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                if viewModel.isLoadingSeats {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Text("\(viewModel.availableSeatsCount) / \(viewModel.totalSeatsCount) Seats Free")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.primary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                let total = max(viewModel.totalSeatsCount, 1)
                let ratio = CGFloat(viewModel.availableSeatsCount) / CGFloat(total)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.surface)
                        .frame(height: 8)

                    Capsule()
                        .fill(AppColors.primary)
                        .frame(width: geo.size.width * ratio, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(AppColors.Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppColors.CornerRadius.md)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
        .padding(.horizontal, AppColors.Spacing.lg)
    }

    // MARK: - Interactive Seat Map Card
    private var interactiveMapCard: some View {
        Button {
            appState.isSeatMapPresented = true
        } label: {
            HStack(spacing: AppColors.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppColors.CornerRadius.md)
                        .fill(AppColors.primaryLight.opacity(0.5))
                        .frame(width: 48, height: 48)
                    Image(systemName: "map.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Interactive Seat Floor Map")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Explore Floor 1 & Floor 2 layout, filters & amenities")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(AppColors.Spacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppColors.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppColors.CornerRadius.md)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, AppColors.Spacing.lg)
    }

    // MARK: - Notice Card
    private var hackathonNoticeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.system(size: 12))
                Text("QR Entry Protocol & Security")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
            }

            Text("Entry QR required before reserving seats. Static QR codes are demo identifiers for hackathon testing and do not replace physical access gates.")
                .font(.system(size: 11))
                .foregroundColor(AppColors.textMuted)
                .lineSpacing(2)
        }
        .padding(AppColors.Spacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppColors.CornerRadius.md)
        .padding(.horizontal, AppColors.Spacing.lg)
    }

    // MARK: - Dynamic State Helpers
    private var statusTitle: String {
        if appState.currentState.isAway {
            return "Stepped Out (Away)"
        }
        if let seat = appState.currentState.seatLabel {
            return "Seat \(seat) Active"
        }
        if appState.currentState.isInside {
            return "Checked In"
        }
        return "Not Checked In"
    }

    private var statusDescription: String {
        if appState.currentState.isAway {
            return "20-minute reservation countdown active"
        }
        if appState.currentState.hasActiveBooking {
            return "Central Library • Continuous Session"
        }
        if appState.currentState.isInside {
            return "Inside library • No seat chosen yet"
        }
        return "Scan ENTRY QR at entrance to begin"
    }

    private var statusColor: Color {
        if appState.currentState.isAway { return AppColors.seatAway }
        if appState.currentState.isInside { return AppColors.primary }
        return AppColors.textSecondary
    }

    private var statusIcon: String {
        if appState.currentState.isAway { return "clock.fill" }
        if appState.currentState.hasActiveBooking { return "chair.lounge.fill" }
        if appState.currentState.isInside { return "checkmark.seal.fill" }
        return "door.left.hand.closed"
    }

    private var scanSubtitle: String {
        if appState.currentState.hasActiveVisit {
            return "Scan EXIT QR or return check-in"
        }
        return "Scan ENTRY turnstile to begin visit"
    }
}
