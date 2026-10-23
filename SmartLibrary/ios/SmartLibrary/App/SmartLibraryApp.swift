import SwiftUI

@main
struct SmartLibraryApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.isStateLoading {
                    // Launch Loading State
                    ZStack {
                        AppColors.background.ignoresSafeArea()
                        VStack(spacing: AppColors.Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                                .scaleEffect(1.3)
                            Text("Connecting to Central Library...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                } else if appState.isAuthenticated {
                    MainTabView()
                        .environmentObject(appState)
                } else {
                    AuthView()
                        .environmentObject(appState)
                }
            }
            .task {
                await appState.checkSession()
            }
        }
    }
}
