#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 4.5 — each card's footnote: a run time, the live line, an estimate.
let cardFootnotes_4_5 = RequirementCase(id: "4.5") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "card-footnotes", id: "4.5")
    }
}
#endif
