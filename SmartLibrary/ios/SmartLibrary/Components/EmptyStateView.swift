import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: AppColors.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textMuted)
                .padding(.bottom, AppColors.Spacing.xs)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, AppColors.Spacing.lg)

            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, AppColors.Spacing.md)
                        .padding(.vertical, AppColors.Spacing.sm)
                        .background(AppColors.primaryLight.opacity(0.5))
                        .cornerRadius(AppColors.CornerRadius.sm)
                }
                .padding(.top, AppColors.Spacing.xs)
            }
        }
        .padding(AppColors.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}
