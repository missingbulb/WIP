import Foundation
import SetlistCore

/// 5.5 — Tapping a told card re-opens it as live and opens a second segment for
/// it, leaving its first segment intact.
let tapToldCard_5_5 = RequirementCase(id: "5.5") {
    let van = Joke(title: "Dad's van", body: "…")
    let airport = Joke(title: "Airport security", body: "…")
    var stage = StageModel(jokes: [van, airport], plannedLength: 1200)

    stage.tapCard(jokeID: van.id, at: CaptureTime(0))
    stage.tapCard(jokeID: airport.id, at: CaptureTime(125))
    let firstVanSegment = stage.segments[0]

    // The callback lands and the comedian goes back to the van.
    let outcome = stage.tapCard(jokeID: van.id, at: CaptureTime(209))

    try expectEqual(outcome, .switched(to: van.id), "tap outcome")
    try expectEqual(stage.liveJokeID, van.id, "the re-opened joke is live")
    try expectEqual(stage.segments.count, 3, "the return opened a third segment")
    try expectEqual(stage.segments[0], firstVanSegment, "the first segment is untouched")
    try expectEqual(stage.segments[2].jokeID, van.id, "the third segment belongs to the re-opened joke")
    try expectEqual(stage.segments[2].start, CaptureTime(209), "the third segment starts at the tap")
}
