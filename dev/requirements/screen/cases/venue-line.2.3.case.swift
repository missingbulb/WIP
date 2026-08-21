#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.3 — the room's name across the top, upper-cased and letter-spaced.
let venueLine_2_3 = RequirementCase(id: "2.3") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "venue-line", id: "2.3", region: .venue)
    }
}
#endif
