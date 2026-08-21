import Foundation
import SetlistCore

/// 4.4 — Laugh events and card taps are ordered on one monotonic clock, so
/// their interleaving is well defined even across a wall-clock change.
let oneCaptureClock_4_4 = RequirementCase(id: "4.4") {
    let airport = UUID()
    let ferry = UUID()

    let taps = [
        TapEvent(at: CaptureTime(120), jokeID: airport),
        TapEvent(at: CaptureTime(204), jokeID: ferry),
    ]
    let laughs = [
        LaughEvent(at: CaptureTime(198), duration: 4.9, kind: .laughter, confidence: 0.9, intensity: 0.8, detector: .soundAnalysis),
        LaughEvent(at: CaptureTime(140), duration: 1.2, kind: .laughter, confidence: 0.7, intensity: 0.4, detector: .soundAnalysis),
        // A laugh landing exactly on a tap belongs to the joke just ended.
        LaughEvent(at: CaptureTime(204), duration: 2.0, kind: .applause, confidence: 0.8, intensity: 0.6, detector: .soundAnalysis),
    ]

    let ordered = timeline(taps: taps, laughs: laughs)
    try expectEqual(ordered.map { $0.at.seconds }, [120, 140, 198, 204, 204], "one ordering over both sources")
    try expectEqual(ordered[3], .tap(taps[1]), "a tap sorts ahead of a laugh sharing its instant")

    // The ordering is the capture clock's, not the wall clock's: nothing in the
    // timeline reads a Date, so a clock change during a set cannot reorder it.
    let reversedInput = timeline(taps: taps.reversed(), laughs: laughs.reversed())
    try expectEqual(reversedInput.map { $0.at.seconds }, ordered.map { $0.at.seconds }, "input order does not matter")
}
