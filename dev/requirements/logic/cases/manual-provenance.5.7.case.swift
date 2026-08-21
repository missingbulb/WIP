import Foundation
import SetlistCore

/// 5.7 — Every segment opened by a card tap records `manual` provenance, so
/// Phase B's proposed boundaries can never be mistaken for the comedian's own.
let manualProvenance_5_7 = RequirementCase(id: "5.7") {
    let jokes = (1 ... 3).map { Joke(title: "Bit \($0)", body: "…") }
    var stage = StageModel(jokes: jokes, plannedLength: 1200)

    stage.tapCard(jokeID: jokes[0].id, at: CaptureTime(0))
    stage.tapCard(jokeID: jokes[1].id, at: CaptureTime(120))
    stage.tapCard(jokeID: jokes[2].id, at: CaptureTime(240))
    stage.endSet(at: CaptureTime(360))

    try expectEqual(stage.segments.count, 3, "one segment per tap")
    for segment in stage.segments {
        try expectEqual(segment.provenance, .manual, "provenance of the segment at \(segment.start.seconds)s")
    }
}
