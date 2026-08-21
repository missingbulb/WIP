import Foundation
import SetlistCore

/// 1.3 — A set is an ordered list of jokes; reordering changes positions only,
/// never joke identity.
let setOrder_1_3 = RequirementCase(id: "1.3") {
    let opener = Joke(title: "Gym induction", body: "…")
    let middle = Joke(title: "Dad's van", body: "…")
    let closer = Joke(title: "The ferry", body: "…")
    var set = SetList(name: "Fri late", jokes: [opener, middle, closer])

    try expectEqual(set.jokes.map(\.id), [opener.id, middle.id, closer.id], "authored order")

    set.move(from: 2, to: 0)
    try expectEqual(set.jokes.map(\.id), [closer.id, opener.id, middle.id], "order after the move")
    try expectEqual(set.jokes.map(\.title), ["The ferry", "Gym induction", "Dad's van"], "titles follow their ids")
    try expectEqual(Set(set.jokes.map(\.id)).count, 3, "no joke was duplicated or replaced")
}
