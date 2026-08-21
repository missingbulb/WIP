import Foundation
import SetlistCore

/// 1.4 — A set's planned length is the sum of its jokes' estimated lengths.
let plannedLength_1_4 = RequirementCase(id: "1.4") {
    let set = SetList(name: "Fri late", jokes: [
        Joke(title: "Gym induction", body: "…", estimatedLength: 150),
        Joke(title: "Dad's van", body: "…", estimatedLength: 125),
        Joke(title: "The ferry", body: "…", estimatedLength: 160),
    ])
    try expectEqual(set.plannedLength, 435, "sum of the estimates")

    // An unestimated joke contributes nothing rather than a guessed average.
    var withUnknown = set
    withUnknown.jokes.append(Joke(title: "Dating apps", body: "…"))
    try expectEqual(withUnknown.plannedLength, 435, "unestimated joke adds nothing")
}
