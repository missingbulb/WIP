#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.6 — the mockup's moment: 1:18 left, the countdown orange.
let countdownWarning_2_6 = RequirementCase(id: "2.6") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state(elapsed: 1122)), slug: "countdown-warning", id: "2.6", region: .clocks)
    }
}
#endif
