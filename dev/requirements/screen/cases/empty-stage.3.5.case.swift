#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.5 — before the first tap: the invitation in the joke region, and a grid with nothing live.
// A whole-screen claim: the leaf is about the screen, not an element in it.

let emptyStage_3_5 = RequirementCase(id: "3.5") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.beforeTheFirstTap()), slug: "empty-stage", id: "3.5")
    }
}
#endif
