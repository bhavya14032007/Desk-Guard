import SwiftUI
import AVFoundation

struct CameraPreview: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        private var hasDetected = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasDetected,
                  let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let stringValue = metadataObject.stringValue else { return }

            hasDetected = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onCodeScanned(stringValue)
        }
    }
}

final class CameraViewController: UIViewController {
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }

    private func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showSimulatorMessage()
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }

            let layer = AVCaptureVideoPreviewLayer(session: captureSession)
            layer.frame = view.layer.bounds
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
            self.previewLayer = layer

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            showSimulatorMessage()
        }
    }

    private func showSimulatorMessage() {
        let label = UILabel()
        label.text = "Camera Unavailable (Simulator Mode)\nUse Demo Scan buttons below"
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
