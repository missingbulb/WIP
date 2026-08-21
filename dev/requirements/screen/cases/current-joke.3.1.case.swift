#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.1 — the joke being performed, its body the largest text on the screen.
let currentJoke_3_1 = RequirementCase(id: "3.1") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "current-joke", id: "3.1")
    }
}
#endif
