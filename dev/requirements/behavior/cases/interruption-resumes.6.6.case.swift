import Foundation
import SetlistCore

/// 6.6 — An audio-session interruption finalises the recording so far and
/// resumes into the same show without losing captured audio.
let interruptionResumes_6_6 = RequirementCase(id: "6.6") {
    let session = FakeRecordingSession()
    let coordinator = CaptureCoordinator(session: session, container: FileManager.default.temporaryDirectory)
    let showID = UUID()

    try coordinator.startShow(showID)
    session.record(120)
    let beforeInterruption = coordinator.now

    // A call arrives mid-set.
    try coordinator.interruptionBegan()
    try expect(!coordinator.isRecording, "the microphone is gone")
    session.gap(30)
    try coordinator.interruptionEnded()
    try expect(coordinator.isRecording, "the show resumed")

    session.record(60)
    let afterInterruption = coordinator.now
    let parts = try coordinator.endShow()

    try expectEqual(parts.count, 2, "the show kept both stretches")
    try expectEqual(session.startedURLs, parts, "every stretch was written somewhere")
    try expect(parts[0] != parts[1], "the second stretch did not overwrite the first")
    try expect(afterInterruption > beforeInterruption, "the clock did not rewind across the gap")
    try expectEqual(afterInterruption, CaptureTime(180), "only recorded seconds count")
}
