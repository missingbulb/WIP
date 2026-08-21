import Foundation
import SetlistCore

/// The fake audio world. It records what the app asked it to do and lets a case
/// drive time forward, which is the whole boundary of what the behavior cases
/// can prove: they confirm this code *asks* for a recording of the right shape,
/// never that AVAudioEngine delivers one. Leaf 4.5 (recording through a locked
/// screen) is the part no fake can stand in for, and stays a tracked gap.
final class FakeRecordingSession: RecordingSession {
    private(set) var startedURLs: [URL] = []
    private(set) var stopCount = 0
    private(set) var captured: TimeInterval = 0
    private(set) var isRunning = false

    func start(writingTo url: URL) throws {
        isRunning = true
        startedURLs.append(url)
    }

    func stop() throws {
        isRunning = false
        stopCount += 1
    }

    /// Audio arrives. Only meaningful while the session runs — the capture
    /// clock counts recorded seconds, not wall-clock ones.
    func record(_ seconds: TimeInterval) {
        guard isRunning else { return }
        captured += seconds
    }

    /// Time passes with the microphone taken away. Nothing is captured, and the
    /// clock does not rewind.
    func gap(_ seconds: TimeInterval) {}
}
