import Foundation
import SetlistCore

/// 3.1 — Tapping a queued card ends the live joke's segment and opens a segment
/// for the tapped joke at the same instant.
let tapQueuedCard_3_1 = RequirementCase(id: "3.1") {
    let van = Joke(title: "Dad's van", body: "…")
    let airport = Joke(title: "Airport security", body: "…")
    var stage = StageModel(setList: SetList(name: "Fri late", jokes: [van, airport]), plannedLength: 1200)

    stage.tapCard(jokeID: van.id, at: CaptureTime(0))
    let outcome = stage.tapCard(jokeID: airport.id, at: CaptureTime(125))

    try expectEqual(outcome, .switched(to: airport.id), "tap outcome")
    try expectEqual(stage.liveJokeID, airport.id, "the tapped joke is live")
    try expectEqual(stage.segments.count, 2, "one segment per tap")

    let closed = stage.segments[0]
    try expectEqual(closed.jokeID, van.id, "the closed segment belongs to the joke that was live")
    try expectEqual(closed.end, CaptureTime(125), "the previous segment closed at the tap")

    let opened = stage.segments[1]
    try expectEqual(opened.jokeID, airport.id, "the opened segment belongs to the tapped joke")
    try expectEqual(opened.start, CaptureTime(125), "no gap between the two segments")
    try expectNil(opened.end, "the new segment is still open")

    try expectEqual(stage.cards.first(where: { $0.id == van.id })?.state, .told, "the previous card reads told")
    try expectEqual(stage.cards.first(where: { $0.id == airport.id })?.state, .live, "the tapped card reads live")
}
