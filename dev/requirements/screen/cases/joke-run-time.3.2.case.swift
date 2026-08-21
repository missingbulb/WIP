#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.2 — the current joke's title with how long it has been running.
let jokeRunTime_3_2 = RequirementCase(id: "3.2") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.state()), slug: "joke-run-time", id: "3.2")
    }
}
#endif
