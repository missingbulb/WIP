#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 4.3 — the key naming the three card states.
let stateKey_4_3 = RequirementCase(id: "4.3") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "state-key", id: "4.3")
    }
}
#endif
