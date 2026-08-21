#if canImport(SwiftUI) && os(iOS)
import SetlistCore
import SetlistUI

/// 9.1 — A whole set, in the five moments a single frame cannot hold: the
/// opener going up, the set moving on, the callback taking the comedian back
/// to a bit they have already told, and the slot running out underneath them.
let workingTheSet_9_1 = sagaCase(
    id: "9.1",
    slug: "working-the-set",
    from: { StageFixture.beforeTheFirstTap() },
    steps: [
        SagaStep("the set is queued and the recording is running; nothing has started yet") { _ in },
        SagaStep("the opener goes up — its card turns live and the joke takes the top of the screen") { state in
            state.tap(StageFixture.jokes[0], at: 0)
            state.elapsed = 40
        },
        SagaStep("three bits in, the set is moving: the told cards go green behind the live one") { state in
            state.tap(StageFixture.jokes[1], at: 190)
            state.tap(StageFixture.jokes[2], at: 315)
            state.tap(StageFixture.jokes[3], at: 423)
            state.elapsed = 507
        },
        SagaStep("the callback lands, so the comedian goes back to the van — it counts once, not twice") { state in
            state.tap(StageFixture.jokes[1], at: 640)
            state.elapsed = 700
        },
        SagaStep("into the closer with 1:18 left, and the countdown has gone orange") { state in
            state.tap(StageFixture.jokes[8], at: 1050)
            state.elapsed = 1122
        },
        SagaStep("a minute over: the countdown is red and counting up") { state in
            state.elapsed = 1260
        },
    ]
)
#endif
