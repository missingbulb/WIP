#if canImport(SwiftUI) && os(iOS)
import SetlistUI

/// 3.5 — before the first tap: no live joke, the region inviting one.
let emptyStage_3_5 = RequirementCase(id: "3.5") {
    try MainActor.assumeIsolated {
        try expectScreen(StageScreen(state: StageFixture.beforeTheFirstTap()), slug: "empty-stage", id: "3.5")
    }
}
#endif
