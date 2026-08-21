#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.10 — The pacing bar carries one segment per joke in set order, sized by estimated length.
let pacingBar_2_10 = RequirementCase(id: "2.10") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "pacing-bar", id: "2.10")
    }
}
#endif
