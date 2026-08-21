#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.14 — A laugh strip runs under the current joke, lit while the live laugh level is above the speak-over threshold.
let laughStrip_2_14 = RequirementCase(id: "2.14") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state(laughLevel: 0.8)), slug: "laugh-strip", id: "2.14")
    }
}
#endif
