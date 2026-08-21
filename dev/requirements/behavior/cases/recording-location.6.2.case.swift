import Foundation
import SetlistCore

/// 6.2 — The recording is written as AAC into the app's own container, in a
/// location the user can delete.
let recordingLocation_6_2 = RequirementCase(id: "6.2") {
    let container = FileManager.default.temporaryDirectory
        .appendingPathComponent("setlist-container-\(UUID().uuidString)")
    let session = FakeRecordingSession()
    let coordinator = CaptureCoordinator(session: session, container: container)
    let showID = UUID()

    try coordinator.startShow(showID)
    session.record(90)
    try coordinator.endShow()

    try expectEqual(session.startedURLs.count, 1, "one file was asked for")
    let url = session.startedURLs[0]
    try expectEqual(url.pathExtension, "m4a", "AAC in an MPEG-4 container")
    try expect(
        url.path.hasPrefix(container.path + "/"),
        "the recording was asked for inside the container, at \(url.path)"
    )
    try expect(url.path.contains(showID.uuidString), "the show's audio is filed under the show")
}
