import SwiftUI

struct ExitChoiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: AppColors.Spacing.lg) {
            // Drag handle
            Capsule()
                .fill(AppColors.border)
                .frame(width: 40, height: 4)
                .padding(.top, AppColors.Spacing.sm)

            // Header
            VStack(spacing: AppColors.Spacing.xs) {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 36))
                    .foregroundColor(AppColors.textPrimary)

                Text("Exiting Central Library")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Are you stepping out temporarily, or leaving for the day?")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppColors.Spacing.lg)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.seatOccupied)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppColors.Spacing.md)
            }

            // Options List
            VStack(spacing: AppColors.Spacing.md) {
                // Option B: Stepping Out (20 min Grace)
                Button {
                    Task {
                        await executeStepOut()
                    }
                } label: {
                    HStack(spacing: AppColors.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.seatAway.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "clock.arrow.2.circlepath")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.seatAway)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stepping Out Temporarily")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Hold my seat for 20 minutes with automatic countdown")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(AppColors.Spacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppColors.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppColors.CornerRadius.lg)
                            .stroke(AppColors.seatAway.opacity(0.3), lineWidth: 1.5)
                    )
                }
                .disabled(isLoading)

                // Option A: Leaving Permanently
                Button {
                    Task {
                        await executeLeavePermanently()
                    }
                } label: {
                    HStack(spacing: AppColors.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.seatOccupied.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.seatOccupied)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Leaving Permanently")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Release seat immediately and complete visit session")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(AppColors.Spacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppColors.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppColors.CornerRadius.lg)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, AppColors.Spacing.lg)

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppColors.textSecondary)
            .padding(.bottom, AppColors.Spacing.lg)
        }
        .presentationDetents([.fraction(0.55), .medium])
    }

    private func executeStepOut() async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await LibraryService.shared.startGracePeriod(libraryId: AppConstants.demoLibraryId)
            RealtimeService.shared.notifySeatMapChanged(libraryId: AppConstants.demoLibraryId, seatId: res.seatId)
            await appState.refreshCurrentState()
            dismiss()
            appState.activeTab = .mySeat
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func executeLeavePermanently() async {
        isLoading = true
        errorMessage = nil
        do {
            let res = try await LibraryService.shared.leaveLibrary(libraryId: AppConstants.demoLibraryId)
            RealtimeService.shared.notifySeatMapChanged(libraryId: AppConstants.demoLibraryId, seatId: res.seatId)
            await appState.refreshCurrentState()
            dismiss()
            appState.activeTab = .home
        } catch let appError as AppError {
            self.errorMessage = appError.localizedDescription
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
