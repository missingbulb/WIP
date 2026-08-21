#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.7 — the room quiet enough to speak into — the same strip dim.
let laughStripDim_3_7 = RequirementCase(id: "3.7") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "laugh-strip-dim", id: "3.7")
    }
}
#endif
