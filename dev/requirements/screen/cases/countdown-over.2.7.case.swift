#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.7 — a minute past the slot: the countdown red, counting up.
let countdownOver_2_7 = RequirementCase(id: "2.7") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state(elapsed: 1260)), slug: "countdown-over", id: "2.7", region: .clocks)
    }
}
#endif
