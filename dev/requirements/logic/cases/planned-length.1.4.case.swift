import Foundation
import SetlistCore

/// 1.4 — A set's planned length is the sum of its jokes' estimated lengths.
let plannedLength_1_4 = RequirementCase(id: "1.4") {
    let jokes = [
        Joke(title: "Gym induction", body: "…", estimatedLength: 150),
        Joke(title: "Dad's van", body: "…", estimatedLength: 125),
        Joke(title: "The ferry", body: "…", estimatedLength: 160),
        Joke(title: "Dating apps", body: "…"),
    ]
    let library = Library(jokes: jokes)

    let estimated = SetList(name: "Fri late", jokeIDs: jokes.prefix(3).map(\.id))
    try expectEqual(library.plannedLength(of: estimated), 435, "sum of the estimates")

    // An unestimated joke contributes nothing rather than a guessed average.
    let withUnknown = SetList(name: "Fri late", jokeIDs: jokes.map(\.id))
    try expectEqual(library.plannedLength(of: withUnknown), 435, "unestimated joke adds nothing")

    // A set naming a joke the library no longer has is shorter, not broken.
    let deleted = SetList(name: "Old set", jokeIDs: [jokes[0].id, UUID()])
    try expectEqual(library.plannedLength(of: deleted), 150, "a deleted joke contributes nothing")
}
