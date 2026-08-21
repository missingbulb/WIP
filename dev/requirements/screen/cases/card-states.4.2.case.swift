#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 4.2 — told, live and queued side by side in one grid.
let cardStates_4_2 = RequirementCase(id: "4.2") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "card-states", id: "4.2", region: .grid)
    }
}
#endif
