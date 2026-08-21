import Foundation
import SetlistCore

/// 3.2 — Tapping the live card changes nothing and opens no zero-length
/// segment. Mid-joke, a comedian's thumb finds its own card constantly.
let tapLiveCard_3_2 = RequirementCase(id: "3.2") {
    let airport = Joke(title: "Airport security", body: "…")
    var stage = StageModel(setList: SetList(name: "Fri late", jokes: [airport]), plannedLength: 1200)

    stage.tapCard(jokeID: airport.id, at: CaptureTime(0))
    let before = stage.segments
    let outcome = stage.tapCard(jokeID: airport.id, at: CaptureTime(84))

    try expectEqual(outcome, .ignored, "tap outcome")
    try expectEqual(stage.segments, before, "no segment was opened or closed")
    try expectEqual(stage.liveJokeID, airport.id, "the joke is still live")
    try expect(!stage.segments.contains(where: { $0.duration == 0 }), "no zero-length segment exists")
}
