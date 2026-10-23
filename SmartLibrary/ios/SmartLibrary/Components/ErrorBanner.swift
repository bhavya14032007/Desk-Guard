import SwiftUI

struct ErrorBanner: View {
    let error: AppError
    let retryAction: (() -> Void)?
    let dismissAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppColors.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.seatOccupied)
                .font(.system(size: 18))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Attention")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.seatOccupied)

                Text(error.localizedDescription)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let retryAction = retryAction {
                    Button(action: retryAction) {
                        Text("Try Again")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.primaryDark)
                            .underline()
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            Button(action: dismissAction) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppColors.Spacing.md)
        .background(Color(red: 0.99, green: 0.95, blue: 0.95))
        .overlay(
            RoundedRectangle(cornerRadius: AppColors.CornerRadius.md)
                .stroke(AppColors.seatOccupied.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(AppColors.CornerRadius.md)
        .padding(.horizontal, AppColors.Spacing.md)
    }
}
