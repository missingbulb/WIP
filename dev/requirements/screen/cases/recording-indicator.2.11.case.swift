#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.11 — A recording indicator is visible in the header whenever capture is running.
let recordingIndicator_2_11 = RequirementCase(id: "2.11") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "recording-indicator", id: "2.11")
    }
}
#endif
