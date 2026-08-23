import AVFoundation
import Flutter

/// The iOS half of the recording seam.
///
/// `AVAudioRecorder` rather than `AVAudioEngine` (decision D10): nothing
/// analyses while capture runs, so no part of the app needs raw PCM, and the
/// high-level recorder already writes AAC and reports a level. Audio never
/// crosses into Dart — only the path to write, the seconds captured, a level,
/// and the interruption transitions.
final class CaptureRecorder: NSObject {
    static let methodChannel = "com.missingbulb.setlist/capture"
    static let eventChannel = "com.missingbulb.setlist/capture-events"

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var sink: FlutterEventSink?

    func register(with registrar: FlutterPluginRegistrar) {
        FlutterMethodChannel(name: Self.methodChannel, binaryMessenger: registrar.messenger())
            .setMethodCallHandler { [weak self] call, result in
                self?.handle(call, result: result)
            }
        FlutterEventChannel(name: Self.eventChannel, binaryMessenger: registrar.messenger())
            .setStreamHandler(self)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
                result(FlutterError(code: "no-path", message: "start needs a path", details: nil))
                return
            }
            do {
                try start(atPath: path)
                result(nil)
            } catch {
                result(FlutterError(code: "start-failed", message: "\(error)", details: nil))
            }
        case "stop":
            stop()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func start(atPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let session = AVAudioSession.sharedInstance()
        // `.record` with the background-audio entitlement is what keeps capture
        // alive behind a locked screen (requirement 6.5).
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let recorder = try AVAudioRecorder(url: url, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128_000,
        ])
        recorder.isMeteringEnabled = true
        recorder.record()
        self.recorder = recorder
        startMetering()
    }

    private func stop() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder else { return }
            recorder.updateMeters()
            self.sink?([
                "type": "level",
                // averagePower is in decibels, -160...0. The strip wants a
                // 0...1 reading, and below -50 dB there is nothing to draw.
                "level": max(0, (recorder.averagePower(forChannel: 0) + 50) / 50),
                "captured": recorder.currentTime,
            ])
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            meterTimer?.invalidate()
            sink?(["type": "interrupted", "cause": "microphoneTaken",
                   "captured": recorder?.currentTime ?? 0])
        case .ended:
            // The coordinator opens a new part rather than resuming into the
            // old file: the clock must not rewind across the gap.
            sink?(["type": "resumed", "captured": recorder?.currentTime ?? 0])
        @unknown default:
            break
        }
    }
}

extension CaptureRecorder: FlutterStreamHandler {
    func onListen(withArguments _: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        sink = eventSink
        return nil
    }

    func onCancel(withArguments _: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}
