import SwiftUI

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ScannerViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                // Live Camera Stream
                CameraPreview { scannedString in
                    Task {
                        await viewModel.handleScannedCode(scannedString, appState: appState)
                    }
                }
                .ignoresSafeArea()

                // Scanner Reticle Overlay
                VStack(spacing: AppColors.Spacing.lg) {
                    Spacer()

                    // Visual Targeting Frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.primary, lineWidth: 3)
                            .frame(width: 250, height: 250)
                            .background(Color.black.opacity(0.15))

                        Image(systemName: "viewfinder")
                            .font(.system(size: 80, weight: .thin))
                            .foregroundColor(.white.opacity(0.8))

                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                                .scaleEffect(1.6)
                        }
                    }

                    // Guidance or Feedback text
                    if let feedback = viewModel.scanSuccessFeedback {
                        Text(feedback)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, AppColors.Spacing.md)
                            .padding(.vertical, AppColors.Spacing.sm)
                            .background(AppColors.primaryDark.opacity(0.9))
                            .cornerRadius(AppColors.CornerRadius.pill)
                    } else {
                        Text("Align the Library QR code inside the box")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, AppColors.Spacing.md)
                            .padding(.vertical, AppColors.Spacing.xs)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(AppColors.CornerRadius.pill)
                    }

                    Spacer()

                    // Simulator Quick Testing Panel
                    VStack(spacing: AppColors.Spacing.sm) {
                        Text("SIMULATOR DEMO CONTROLS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: AppColors.Spacing.md) {
                            Button {
                                let payload = "SLMS|ENTRY|\(AppConstants.demoLibraryIdString)"
                                Task {
                                    await viewModel.handleScannedCode(payload, appState: appState)
                                }
                            } label: {
                                Label("ENTRY QR", systemImage: "arrow.down.right.circle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppColors.Spacing.md)
                                    .padding(.vertical, AppColors.Spacing.sm)
                                    .background(AppColors.primary)
                                    .cornerRadius(AppColors.CornerRadius.md)
                            }

                            Button {
                                let payload = "SLMS|EXIT|\(AppConstants.demoLibraryIdString)"
                                Task {
                                    await viewModel.handleScannedCode(payload, appState: appState)
                                }
                            } label: {
                                Label("EXIT QR", systemImage: "arrow.up.left.circle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppColors.Spacing.md)
                                    .padding(.vertical, AppColors.Spacing.sm)
                                    .background(AppColors.seatOccupied)
                                    .cornerRadius(AppColors.CornerRadius.md)
                            }
                        }
                    }
                    .padding(AppColors.Spacing.md)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(AppColors.CornerRadius.lg)
                    .padding(.horizontal, AppColors.Spacing.md)
                    .padding(.bottom, AppColors.Spacing.md)
                }
            }
            .navigationTitle("Scan Library QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert(isPresented: $viewModel.isAlertPresented) {
                Alert(
                    title: Text("Scan Error"),
                    message: Text(viewModel.alertMessage ?? "Unable to process QR code."),
                    dismissButton: .default(Text("OK")) {
                        viewModel.resetScanner()
                    }
                )
            }
        }
    }
}

#Preview {
    QRScannerView()
        .environmentObject(AppState())
}
