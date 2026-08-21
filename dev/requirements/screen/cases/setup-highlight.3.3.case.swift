#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.3 — the crucial setup picked out of the body in orange.
let setupHighlight_3_3 = RequirementCase(id: "3.3") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "setup-highlight", id: "3.3", region: .jokeBody)
    }
}
#endif
