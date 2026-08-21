#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.8 — The countdown is subordinate to the joke text and shows remaining, elapsed and planned time.
let countdownHeader_2_8 = RequirementCase(id: "2.8") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state(elapsed: 1122)), slug: "countdown-header", id: "2.8")
    }
}
#endif
