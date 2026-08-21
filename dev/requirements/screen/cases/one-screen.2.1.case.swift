#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.1 — the whole screen at the reference moment: header, current joke, switch row and the nine-card grid, nothing clipped and nothing to scroll.
// A whole-screen claim: the leaf is about the screen, not an element in it.

let oneScreen_2_1 = RequirementCase(id: "2.1") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "one-screen", id: "2.1")
    }
}
#endif
