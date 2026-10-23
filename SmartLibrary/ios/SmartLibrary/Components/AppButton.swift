import SwiftUI

enum AppButtonStyle {
    case primary
    case secondary
    case destructive
}

struct AppButton: View {
    let title: String
    let icon: String?
    let style: AppButtonStyle
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: AppButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppColors.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(AppColors.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppColors.CornerRadius.md)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppColors.primary
        case .secondary:
            return AppColors.cardBackground
        case .destructive:
            return Color(red: 0.99, green: 0.93, blue: 0.93)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return AppColors.primary
        case .destructive:
            return AppColors.seatOccupied
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary:
            return AppColors.primary
        case .destructive:
            return AppColors.seatOccupied.opacity(0.3)
        case .primary:
            return .clear
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return AppColors.primary.opacity(0.2)
        default:
            return Color.clear
        }
    }
}
