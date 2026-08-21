import Foundation
import SetlistCore

/// 3.4 — Card taps are stamped on the capture clock, so a tap's timestamp is
/// comparable with a laugh event's without conversion.
let tapOnCaptureClock_3_4 = RequirementCase(id: "3.4") {
    let session = FakeRecordingSession()
    let coordinator = CaptureCoordinator(session: session, container: FileManager.default.temporaryDirectory)
    let van = Joke(title: "Dad's van", body: "…")
    let airport = Joke(title: "Airport security", body: "…")
    var stage = StageModel(jokes: [van, airport], plannedLength: 1200)

    try coordinator.startShow(UUID())
    stage.tapCard(jokeID: van.id, at: coordinator.now)
    try expectEqual(stage.segments[0].start, CaptureTime(0), "the first tap lands at the start of the recording")

    session.record(125)
    let switchInstant = coordinator.now
    stage.tapCard(jokeID: airport.id, at: switchInstant)

    // The stamp is the recording's own position, so it indexes into the audio.
    try expectEqual(switchInstant, CaptureTime(125), "the tap is stamped with recorded seconds")
    try expectEqual(stage.segments[1].start, switchInstant, "the segment carries the tap's stamp")

    // A laugh detected two seconds later needs no conversion to be placed
    // against that tap.
    session.record(2)
    let laugh = LaughEvent(
        at: coordinator.now,
        duration: 4.9,
        kind: .laughter,
        confidence: 0.9,
        intensity: 0.8,
        detector: .soundAnalysis
    )
    let ordered = timeline(taps: [TapEvent(at: switchInstant, jokeID: airport.id)], laughs: [laugh])
    try expectEqual(ordered.map { $0.at.seconds }, [125, 127], "one ordering, no conversion")
    try expect(laugh.at > stage.segments[1].start, "the laugh belongs to the joke that was live")
}
