#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.6 — Told, live and queued cards are each coloured differently, with a key naming the three states.
let cardStates_2_6 = RequirementCase(id: "2.6") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "card-states", id: "2.6")
    }
}
#endif
