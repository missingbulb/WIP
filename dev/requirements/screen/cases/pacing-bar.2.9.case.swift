#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.9 — the set's shape in one strip — three told, one live, five queued, each sized by its estimate.
let pacingBar_2_9 = RequirementCase(id: "2.9") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "pacing-bar", id: "2.9")
    }
}
#endif
