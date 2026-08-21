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
            body: "Every room has one man who answers a rhetorical question. Tonight it is you, and the whole room has noticed.",
            estimatedLength: 190
        ),
        Joke(title: "Dad's van", body: "My dad drove a van with no back seats, so my childhood was spent sliding around in the boot like unsecured cargo, which is legally what I was.", estimatedLength: 125),
        Joke(title: "Flatmate rota", body: "We have a cleaning rota on the fridge. It has been there two years. It is the cleanest thing in the flat.", estimatedLength: 110),
        Joke(
            title: "Airport security",
            body: "They make you take off your shoes but not your socks — which tells me the threat level is exactly one layer deep.",
            setups: [Joke.SetupSpan(start: 0, length: 52)],
            notes: ["…beat… I've been wearing the same socks since Tuesday."],
            tags: ["alt tag: TSA loyalty card", "cut if short"],
            estimatedLength: 145
        ),
        Joke(title: "Gym induction", body: "The induction guy asked what my goals were and I said stairs, and then he wrote it down, which was worse.", estimatedLength: 150),
        Joke(title: "Wedding speech", body: "I was asked to do a reading at a wedding, which is what you say to someone you like but would not trust with a microphone.", estimatedLength: 180),
        Joke(title: "Nan's iPad", body: "My nan holds her iPad like it is a hostage situation and she is the negotiator.", estimatedLength: 100),
        Joke(title: "Dating apps", body: "My profile says I like long walks, which is true, because I cannot afford anywhere to go.", estimatedLength: 135),
        Joke(title: "Closer — the ferry", body: "The last ferry leaves at eleven, so every romance on that island has a hard deadline.", estimatedLength: 160),
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

    /// The set as it stands before the comedian taps anything: everything
    /// queued, the recording already running.
    static func beforeTheFirstTap() -> StageState {
        StageState(
            model: StageModel(jokes: jokes, plannedLength: 1200),
            venue: "The Stand · Fri late",
            elapsed: 0
        )
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

/// Driving the fixture forward, for the sagas: a card tap at a moment on the
/// capture clock. Test-side only — the app drives the same model through the
/// stage screen's own callbacks.
extension StageState {
    mutating func tap(_ joke: Joke, at seconds: TimeInterval) {
        model.tapCard(jokeID: joke.id, at: CaptureTime(seconds))
    }
}
#endif
