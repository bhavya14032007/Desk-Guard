import SwiftUI
import AVFoundation

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var alertMessage: String? = nil
    @Published var isAlertPresented: Bool = false
    @Published var cameraPermissionGranted: Bool = false
    @Published var scanSuccessFeedback: String? = nil

    private var hasScanned: Bool = false

    init() {
        checkCameraPermission()
    }

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                }
            }
        default:
            cameraPermissionGranted = false
        }
    }

    /// Reset scanner to allow another scan
    func resetScanner() {
        hasScanned = false
        isProcessing = false
        scanSuccessFeedback = nil
    }

    /// Process raw QR string received from camera or simulator action
    func handleScannedCode(_ code: String, appState: AppState) async {
        guard !hasScanned, !isProcessing else { return }
        hasScanned = true
        isProcessing = true

        // Strict parsing
        let parseResult = QRPayload.parse(code)
        switch parseResult {
        case .failure(let error):
            showAlert(error.localizedDescription)
            isProcessing = false
            hasScanned = false
            return

        case .success(let payload):
            // Check library UUID
            guard payload.libraryId == AppConstants.demoLibraryId else {
                showAlert("This QR code belongs to a different library. Please scan Central Library's QR code.")
                isProcessing = false
                hasScanned = false
                return
            }

            switch payload.type {
            case .entry:
                await handleEntryScan(libraryId: payload.libraryId, appState: appState)
            case .exit:
                handleExitScan(appState: appState)
            }
        }

        isProcessing = false
    }

    private func handleEntryScan(libraryId: UUID, appState: AppState) async {
        do {
            let response = try await LibraryService.shared.scanEntry(libraryId: libraryId)
            await appState.refreshCurrentState()

            switch response.result {
            case "entered":
                scanSuccessFeedback = "Welcome to Central Library! Please select a seat."
                try? await Task.sleep(nanoseconds: 800_000_000)
                appState.isScannerPresented = false
                appState.isSeatMapPresented = true

            case "already_inside":
                scanSuccessFeedback = "You are already checked in to Central Library."
                try? await Task.sleep(nanoseconds: 800_000_000)
                appState.isScannerPresented = false
                if !appState.currentState.hasActiveBooking {
                    appState.isSeatMapPresented = true
                }

            case "returned":
                scanSuccessFeedback = "Welcome back! Your seat reservation has been restored."
                try? await Task.sleep(nanoseconds: 900_000_000)
                appState.isScannerPresented = false
                appState.activeTab = .mySeat

            case "grace_expired_new_visit":
                scanSuccessFeedback = "Your 20-min grace period expired. Old seat was released. Welcome back!"
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                appState.isScannerPresented = false
                appState.isSeatMapPresented = true

            default:
                scanSuccessFeedback = "Entry recorded."
                try? await Task.sleep(nanoseconds: 600_000_000)
                appState.isScannerPresented = false
            }
        } catch let appError as AppError {
            showAlert(appError.localizedDescription)
            hasScanned = false
        } catch {
            showAlert(error.localizedDescription)
            hasScanned = false
        }
    }

    private func handleExitScan(appState: AppState) {
        // Exit QR must open choice sheet, not auto-release
        appState.isScannerPresented = false
        appState.isExitChoicePresented = true
    }

    private func showAlert(_ message: String) {
        self.alertMessage = message
        self.isAlertPresented = true
    }
}
