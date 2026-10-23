import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppColors.Spacing.xl) {
                    // Header Logo & Branding
                    VStack(spacing: AppColors.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryLight)
                                .frame(width: 80, height: 80)
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 38))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(.top, AppColors.Spacing.xl)

                        Text(AppConstants.appName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)

                        Text("Smart Seat & Visit Management")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Sign In / Sign Up Segmented Toggle
                    Picker("Authentication Mode", selection: $viewModel.isSignUp) {
                        Text("Sign In").tag(false)
                        Text("Create Account").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppColors.Spacing.lg)

                    // Input Form Card
                    VStack(spacing: AppColors.Spacing.md) {
                        if let error = viewModel.errorMessage {
                            HStack(spacing: AppColors.Spacing.xs) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(AppColors.seatOccupied)
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.seatOccupied)
                            }
                            .padding(.vertical, AppColors.Spacing.xs)
                        }

                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(AppColors.textMuted)
                                    .frame(width: 24)
                                TextField("student@university.edu", text: $viewModel.email)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .disableAutocorrection(true)
                            }
                            .padding(AppColors.Spacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppColors.CornerRadius.md)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(AppColors.textMuted)
                                    .frame(width: 24)
                                SecureField("••••••••", text: $viewModel.password)
                            }
                            .padding(AppColors.Spacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppColors.CornerRadius.md)
                        }

                        // Action Button
                        AppButton(
                            viewModel.isSignUp ? "Create Student Account" : "Sign In to Library",
                            icon: viewModel.isSignUp ? "person.badge.plus" : "arrow.right.circle.fill",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.authenticate(appState: appState)
                            }
                        }
                        .padding(.top, AppColors.Spacing.sm)
                    }
                    .padding(AppColors.Spacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppColors.CornerRadius.lg)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, AppColors.Spacing.lg)

                    // Footer Notice
                    VStack(spacing: 4) {
                        Text("Connected to Central Library Hub")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textMuted)
                        Text("24h Hackathon Build • Supabase Backend")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(.top, AppColors.Spacing.md)
                }
            }
        }
    }
}
