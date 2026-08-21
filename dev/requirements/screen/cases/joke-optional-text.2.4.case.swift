#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 2.4 — The current joke's optional text renders below the body as tags.
let jokeOptionalText_2_4 = RequirementCase(id: "2.4") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "joke-optional-text", id: "2.4")
    }
}
#endif
