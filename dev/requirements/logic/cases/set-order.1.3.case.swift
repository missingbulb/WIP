import Foundation
import SetlistCore

/// 1.3 — A set is an ordered list of jokes; reordering changes positions only,
/// never joke identity.
let setOrder_1_3 = RequirementCase(id: "1.3") {
    let opener = Joke(title: "Gym induction", body: "…")
    let middle = Joke(title: "Dad's van", body: "…")
    let closer = Joke(title: "The ferry", body: "…")
    let library = Library(jokes: [opener, middle, closer])
    var set = SetList(name: "Fri late", jokeIDs: [opener.id, middle.id, closer.id])

    try expectEqual(library.jokes(of: set).map(\.title), ["Gym induction", "Dad's van", "The ferry"], "authored order")

    set.move(from: 2, to: 0)
    try expectEqual(set.jokeIDs, [closer.id, opener.id, middle.id], "order after the move")
    try expectEqual(library.jokes(of: set).map(\.title), ["The ferry", "Gym induction", "Dad's van"], "titles follow their ids")
    try expectEqual(Set(set.jokeIDs).count, 3, "no joke was duplicated or replaced")

    // The set holds references, so editing a joke in the library edits it on
    // every set list it appears in.
    var edited = library
    edited.jokes[0].title = "Gym induction (new tag)"
    try expectEqual(edited.jokes(of: set).map(\.title), ["The ferry", "Gym induction (new tag)", "Dad's van"], "an edit reaches the set")
}
