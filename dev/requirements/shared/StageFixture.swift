#if canImport(SwiftUI) && os(iOS)
import Foundation
import SetlistCore
import SetlistUI

/// The set every screen case renders: the mockup's nine bits, mid-show. One
/// fixture across the screen kind means the goldens differ only where the
/// requirement under test differs.
enum StageFixture {
    static let jokes: [Joke] = [
        Joke(
            title: "Crowd work",
            body: "…",
            estimatedLength: 190
        ),
        Joke(title: "Dad's van", body: "…", estimatedLength: 125),
        Joke(title: "Flatmate rota", body: "…", estimatedLength: 110),
        Joke(
            title: "Airport security",
            body: "They make you take off your shoes but not your socks — which tells me the threat level is exactly one layer deep.",
            setups: [Joke.SetupSpan(start: 0, length: 52)],
            notes: ["…beat… I've been wearing the same socks since Tuesday."],
            tags: ["alt tag: TSA loyalty card", "cut if short"],
            estimatedLength: 145
        ),
        Joke(title: "Gym induction", body: "…", estimatedLength: 150),
        Joke(title: "Wedding speech", body: "…", estimatedLength: 180),
        Joke(title: "Nan's iPad", body: "…", estimatedLength: 100),
        Joke(title: "Dating apps", body: "…", estimatedLength: 135),
        Joke(title: "Closer — the ferry", body: "…", estimatedLength: 160),
    ]

    /// Three bits told, the fourth live for 1:24, five queued — the mockup's
    /// moment.
    static func midShow(autodetectAvailable: Bool = false) -> StageModel {
        var model = StageModel(jokes: jokes, plannedLength: 1200)
        model.tapCard(jokeID: jokes[0].id, at: CaptureTime(0))
        model.tapCard(jokeID: jokes[1].id, at: CaptureTime(190))
        model.tapCard(jokeID: jokes[2].id, at: CaptureTime(315))
        model.tapCard(jokeID: jokes[3].id, at: CaptureTime(423))
        return model
    }

    static func state(elapsed: TimeInterval = 507, laughLevel: Double = 0) -> StageState {
        StageState(
            model: midShow(),
            venue: "The Stand · Fri late",
            elapsed: elapsed,
            laughLevel: laughLevel
        )
    }
}
#endif
