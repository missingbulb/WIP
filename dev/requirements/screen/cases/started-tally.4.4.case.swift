#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 4.4 — the list header counting what has been started out of what is planned.
let startedTally_4_4 = RequirementCase(id: "4.4") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "started-tally", id: "4.4")
    }
}
#endif
