import SwiftUI

/// Semantic design tokens for Smart Library Management System
/// Clean, modern, minimal aesthetic with 8px grid layout and dark navy/charcoal typography.
enum AppColors {
    // Primary Action
    static let primary = Color(red: 0.02, green: 0.59, blue: 0.41)      // Emerald Green (#059669)
    static let primaryLight = Color(red: 0.82, green: 0.96, blue: 0.89) // Emerald Tint
    static let primaryDark = Color(red: 0.02, green: 0.47, blue: 0.33)  // Deep Emerald

    // Backgrounds & Neutrals
    static let background = Color(red: 0.97, green: 0.98, blue: 0.99)   // Light Grey (#F8FAFC)
    static let cardBackground = Color.white                             // Pure White
    static let surface = Color(red: 0.94, green: 0.96, blue: 0.98)      // Subtle Neutral (#F1F5F9)
    static let border = Color(red: 0.89, green: 0.91, blue: 0.93)       // Soft Border (#E2E8F0)

    // Typography
    static let textPrimary = Color(red: 0.06, green: 0.09, blue: 0.16)  // Dark Navy/Charcoal (#0F172A)
    static let textSecondary = Color(red: 0.40, green: 0.45, blue: 0.53)// Slate Grey (#64748B)
    static let textMuted = Color(red: 0.58, green: 0.64, blue: 0.72)    // Light Slate (#94A3B8)

    // Status Colors (Seat states)
    static let seatAvailable = Color(red: 0.06, green: 0.73, blue: 0.51)// Vibrant Green (#10B981)
    static let seatOccupied = Color(red: 0.94, green: 0.27, blue: 0.24) // Crimson Red (#EF4444)
    static let seatAway = Color(red: 0.96, green: 0.62, blue: 0.11)     // Warm Amber (#F59E0B)
    static let seatMine = Color(red: 0.15, green: 0.47, blue: 0.95)     // Royal Blue (#2563EB)

    // Spacing (8px Grid System)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // Corner Radii
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let pill: CGFloat = 999
    }
}
