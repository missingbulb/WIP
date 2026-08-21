import Foundation
import SetlistCore

/// 1.1 — A joke carries a title, body text, delivery notes, tags, callback
/// references and an estimated length.
let jokeFields_1_1 = RequirementCase(id: "1.1") {
    let callback = UUID()
    let joke = Joke(
        title: "Airport security",
        body: "They make you take off your shoes but not your socks.",
        notes: ["…beat… I've been wearing the same socks since Tuesday."],
        tags: ["alt tag: TSA loyalty card", "cut if short"],
        callbacks: [callback],
        estimatedLength: 150
    )

    try expectEqual(joke.title, "Airport security", "title")
    try expect(joke.body.contains("shoes"), "body carries the joke's text")
    try expectEqual(joke.notes.count, 1, "delivery notes")
    try expectEqual(joke.tags.count, 2, "tags")
    try expectEqual(joke.callbacks, [callback], "callback references")
    try expectEqual(joke.estimatedLength, 150, "estimated length")

    // A joke with no estimate has none — never a zero standing in for unknown.
    try expectNil(Joke(title: "Untested", body: "…").estimatedLength, "unestimated joke")

    let decoded = try JSONDecoder().decode(Joke.self, from: JSONEncoder().encode(joke))
    try expectEqual(decoded, joke, "round-tripped joke")
}
