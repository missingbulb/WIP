#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.4 — the alternate tags under the body, bordered and secondary to the joke.
let jokeOptionalText_3_4 = RequirementCase(id: "3.4") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "joke-optional-text", id: "3.4")
    }
}
#endif
