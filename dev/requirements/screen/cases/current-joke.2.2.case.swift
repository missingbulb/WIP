#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.2 — The current joke occupies the top region, its body text the largest text on the screen.
let currentJoke_2_2 = RequirementCase(id: "2.2") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "current-joke", id: "2.2")
    }
}
#endif
