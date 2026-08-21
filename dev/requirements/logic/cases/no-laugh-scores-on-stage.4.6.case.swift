import Foundation
import SetlistCore

/// 4.6 — No stage-mode card carries a laugh count or laugh score.
///
/// Asserted against the card's shape rather than a render: a golden proves only
/// that today's state shows no number, while a field that does not exist cannot
/// reach any state's layout.
let noLaughScoresOnStage_4_6 = RequirementCase(id: "4.6") {
    let card = StageCard(joke: Joke(title: "Airport security", body: "…"))
    let forbidden = ["laugh", "score", "peak", "applause", "rating"]

    for child in Mirror(reflecting: card).children {
        let label = (child.label ?? "").lowercased()
        for word in forbidden {
            try expect(!label.contains(word), "stage card exposes \(label), which is laugh data")
        }
    }

    // The joke a card renders must not smuggle one in either.
    for child in Mirror(reflecting: card.joke).children {
        let label = (child.label ?? "").lowercased()
        for word in forbidden {
            try expect(!label.contains(word), "the joke behind a stage card exposes \(label)")
        }
    }
}
