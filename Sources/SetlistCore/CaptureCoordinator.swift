import Foundation

/// The recording session the coordinator drives. The shipping implementation
/// wraps AVAudioEngine; the requirement cases drive a fake, so what they prove
/// is that this code *asks* for the right thing, never that the platform
/// performs it.
public protocol RecordingSession: AnyObject {
    /// Seconds of audio captured so far — the monotonic source both card taps
    /// and laugh events are stamped against.
    var captured: TimeInterval { get }
    var isRunning: Bool { get }
    func start(writingTo url: URL) throws
    func stop() throws
}

/// Owns the recording for one show: when it runs, where its audio goes, and the
/// clock everything else timestamps against.
public final class CaptureCoordinator {
    /// The container the recording is written inside. Everything here is
    /// deleted when the user deletes the app.
    public let container: URL
    private let session: RecordingSession
    /// One file per uninterrupted stretch of recording. A show with no
    /// interruption has exactly one.
    public private(set) var parts: [URL] = []
    public private(set) var showID: UUID?

    public init(session: RecordingSession, container: URL) {
        self.session = session
        self.container = container
    }

    public var isRecording: Bool { session.isRunning }

    /// The instant to stamp a card tap or a laugh event with.
    public var now: CaptureTime { CaptureTime(session.captured) }

    public func startShow(_ showID: UUID) throws {
        self.showID = showID
        parts = []
        try startPart()
    }

    /// The audio session was taken away — a call, another app. The stretch so
    /// far is closed rather than abandoned.
    public func interruptionBegan() throws {
        guard session.isRunning else { return }
        try session.stop()
    }

    /// The audio session came back. The show continues into a new stretch; the
    /// clock never rewinds, so timestamps stay comparable across the gap.
    public func interruptionEnded() throws {
        guard showID != nil, !session.isRunning else { return }
        try startPart()
    }

    /// Ends the show and hands back its audio, in order.
    @discardableResult
    public func endShow() throws -> [URL] {
        if session.isRunning { try session.stop() }
        showID = nil
        return parts
    }

    private func startPart() throws {
        guard let showID else { return }
        // AAC in an MPEG-4 container: the format the architecture's ~60 MB
        // hour is sized for.
        let url = container
            .appendingPathComponent("shows/\(showID.uuidString)")
            .appendingPathComponent("part-\(parts.count).m4a")
        try session.start(writingTo: url)
        parts.append(url)
    }
}
