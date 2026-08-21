#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.5 — The set list renders as a 3-column grid of nine cards, each card
/// carrying its joke's title.
let setListGrid_2_5 = RequirementCase(id: "2.5") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "set-list-grid", id: "2.5")
    }
}
#endif
