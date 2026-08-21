#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.6 — the room louder than the comedian can talk over — the strip lit.
let laughStripLit_3_6 = RequirementCase(id: "3.6") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state(laughLevel: 0.8)), slug: "laugh-strip-lit", id: "3.6", region: .laughStrip)
    }
}
#endif
