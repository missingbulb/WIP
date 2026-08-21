#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.2 — the red dot at the head of the header while capture runs.
let recordingIndicator_2_2 = RequirementCase(id: "2.2") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "recording-indicator", id: "2.2", region: .venue)
    }
}
#endif
