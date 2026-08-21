#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 4.1 — nine cards in three columns, filling the height the joke panel leaves.
let setListGrid_4_1 = RequirementCase(id: "4.1") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "set-list-grid", id: "4.1", region: .grid)
    }
}
#endif
