#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.4 — elapsed over planned beside the countdown, in the screen's one m:ss format.
let elapsedAndPlanned_2_4 = RequirementCase(id: "2.4") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "elapsed-and-planned", id: "2.4", region: .clocks)
    }
}
#endif
