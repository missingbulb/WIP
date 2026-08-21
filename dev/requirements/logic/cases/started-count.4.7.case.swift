import Foundation
import SetlistCore

/// 4.7 — The set-list header counts jokes started out of jokes planned,
/// counting a re-opened joke once.
let startedCount_4_7 = RequirementCase(id: "4.7") {
    let jokes = (1 ... 9).map { Joke(title: "Bit \($0)", body: "…") }
    var stage = StageModel(jokes: jokes, plannedLength: 1200)

    try expectEqual(stage.startedCount, 0, "nothing started yet")
    try expectEqual(stage.plannedCount, 9, "jokes planned")

    stage.tapCard(jokeID: jokes[0].id, at: CaptureTime(0))
    stage.tapCard(jokeID: jokes[1].id, at: CaptureTime(190))
    stage.tapCard(jokeID: jokes[2].id, at: CaptureTime(315))
    stage.tapCard(jokeID: jokes[3].id, at: CaptureTime(423))
    try expectEqual(stage.startedCount, 4, "four of nine started")

    // Going back to an earlier bit does not make it a fifth.
    stage.tapCard(jokeID: jokes[1].id, at: CaptureTime(507))
    try expectEqual(stage.startedCount, 4, "a re-opened joke counts once")
}
