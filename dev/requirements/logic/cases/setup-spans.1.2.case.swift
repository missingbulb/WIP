import Foundation
import SetlistCore

/// 1.2 — Crucial-setup spans survive an encode/decode round-trip with their
/// character offsets intact.
let setupSpans_1_2 = RequirementCase(id: "1.2") {
    // A body with characters outside ASCII: an offset stored as a UTF-8 byte
    // count would drift here and the highlight would land on the wrong words.
    let body = "Se llama “seguridad” — they make you take off your shoes but not your socks."
    guard let range = body.range(of: "they make you take off your shoes but not your socks") else {
        throw RequirementFailure(description: "fixture body lost its setup phrase")
    }
    let start = body.distance(from: body.startIndex, to: range.lowerBound)
    let length = body.distance(from: range.lowerBound, to: range.upperBound)
    let joke = Joke(
        title: "Airport security",
        body: body,
        setups: [Joke.SetupSpan(start: start, length: length)]
    )

    try expectEqual(
        joke.setupText(joke.setups[0]),
        "they make you take off your shoes but not your socks",
        "setup text before the round-trip"
    )

    let decoded = try JSONDecoder().decode(Joke.self, from: JSONEncoder().encode(joke))
    try expectEqual(decoded.setups, joke.setups, "spans survive the round-trip")
    try expectEqual(
        decoded.setupText(decoded.setups[0]),
        "they make you take off your shoes but not your socks",
        "setup text after the round-trip"
    )
}
