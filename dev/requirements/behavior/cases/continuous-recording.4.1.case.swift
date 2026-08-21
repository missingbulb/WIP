import Foundation
import SetlistCore

/// 4.1 — Recording starts when the show starts and runs unbroken to the end of
/// the set.
let continuousRecording_4_1 = RequirementCase(id: "4.1") {
    let session = FakeRecordingSession()
    let coordinator = CaptureCoordinator(session: session, container: FileManager.default.temporaryDirectory)
    let jokes = (1 ... 3).map { Joke(title: "Bit \($0)", body: "…") }
    var stage = StageModel(jokes: jokes, plannedLength: 1200)

    try expect(!coordinator.isRecording, "nothing records before the show starts")

    try coordinator.startShow(UUID())
    try expect(coordinator.isRecording, "the show starts recording")

    // Moving through the set does not touch the recording — segmentation is
    // bookkeeping over one unbroken file.
    for (index, joke) in jokes.enumerated() {
        session.record(120)
        stage.tapCard(jokeID: joke.id, at: coordinator.now)
        try expect(coordinator.isRecording, "still recording at bit \(index + 1)")
        try expectEqual(session.stopCount, 0, "nothing stopped the recording at bit \(index + 1)")
    }

    session.record(60)
    stage.endSet(at: coordinator.now)
    let parts = try coordinator.endShow()

    try expectEqual(session.stopCount, 1, "the recording stopped once, at the end")
    try expectEqual(parts.count, 1, "an uninterrupted show is one unbroken recording")
    try expect(!coordinator.isRecording, "nothing records after the show")
}
