import SwiftUI

struct TemporaryAwayView: View {
    @ObservedObject var viewModel: MySeatViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: AppColors.Spacing.xl) {
            Spacer()

            // Countdown Circle
            ZStack {
                Circle()
                    .stroke(AppColors.surface, lineWidth: 12)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppColors.seatAway,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: progress)

                VStack(spacing: 4) {
                    Text(AppDateFormatter.formatCountdown(viewModel.remainingSeconds))
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Time Remaining")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            // Status message
            VStack(spacing: AppColors.Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .foregroundColor(AppColors.seatAway)
                    Text("Seat Reserved (Stepped Out)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }

                if let label = appState.currentState.seatLabel {
                    Text("Your Seat: **\(label)**")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                Text("Your reservation is held for 20 minutes from stepping out. When you return, scan the Central Library ENTRY QR code to unlock your seat.")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, AppColors.Spacing.xl)
            }

            Spacer()

            // Actions
            VStack(spacing: AppColors.Spacing.md) {
                AppButton(
                    "Scan ENTRY QR to Return",
                    icon: "qrcode.viewfinder",
                    style: .primary
                ) {
                    appState.isScannerPresented = true
                }

                AppButton(
                    "Leave Library Permanently",
                    icon: "arrow.right.square",
                    style: .destructive,
                    isLoading: viewModel.isActionLoading
                ) {
                    Task {
                        await viewModel.leavePermanently(appState: appState)
                    }
                }
            }
            .padding(.horizontal, AppColors.Spacing.lg)
            .padding(.bottom, AppColors.Spacing.lg)
        }
        .onAppear {
            viewModel.updateCountdown(from: appState.currentState.graceDeadline)
        }
    }

    private var progress: CGFloat {
        let total = CGFloat(AppConstants.graceDurationMinutes * 60)
        let current = CGFloat(viewModel.remainingSeconds)
        return min(max(current / total, 0), 1.0)
    }
}
