#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.5 — the countdown with eleven minutes still in hand — bone, not shouting.
let countdownNeutral_2_5 = RequirementCase(id: "2.5") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "countdown-neutral", id: "2.5", region: .clocks)
    }
}
#endif
