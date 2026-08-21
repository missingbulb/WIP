#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.3 — Crucial setups render highlighted inside the current joke's body.
let setupHighlight_2_3 = RequirementCase(id: "2.3") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "setup-highlight", id: "2.3")
    }
}
#endif
