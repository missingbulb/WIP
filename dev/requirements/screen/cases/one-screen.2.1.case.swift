#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.1 — The stage screen fills one portrait iPad screen at 3:4 with no scrolling region.
let oneScreen_2_1 = RequirementCase(id: "2.1") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "one-screen", id: "2.1")
    }
}
#endif
