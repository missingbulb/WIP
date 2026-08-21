#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.1 — the joke panel against the rest of the screen, which is what makes its body the largest text on it.
// A whole-screen claim: the leaf is about the screen, not an element in it.

let currentJoke_3_1 = RequirementCase(id: "3.1") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "current-joke", id: "3.1")
    }
}
#endif
