import Foundation
import SetlistCore

/// 6.3 — A laugh event carries its class, confidence, start, duration,
/// intensity and the identifier of the detector that produced it.
let laughEventFields_6_3 = RequirementCase(id: "6.3") {
    let event = LaughEvent(
        at: CaptureTime(212.5),
        duration: 4.9,
        kind: .laughter,
        confidence: 0.86,
        intensity: 0.71,
        detector: .soundAnalysis
    )

    try expectEqual(event.at, CaptureTime(212.5), "start")
    try expectEqual(event.duration, 4.9, "duration")
    try expectEqual(event.kind, .laughter, "class")
    try expectEqual(event.confidence, 0.86, "confidence")
    try expectEqual(event.intensity, 0.71, "intensity")
    try expectEqual(event.detector, .soundAnalysis, "detector")

    // Applause and cheering are their own classes, not laughter with a low
    // confidence — the club's noise is what the detector has to tell apart.
    let applause = LaughEvent(
        at: CaptureTime(600),
        duration: 8,
        kind: .applause,
        confidence: 0.93,
        intensity: 0.9,
        detector: .soundAnalysis
    )
    try expectEqual(applause.kind, .applause, "applause is its own class")

    // The detector survives storage: an event whose source is unknown would
    // silently mix two uncalibrated scales in cross-show analysis (D3).
    let decoded = try JSONDecoder().decode(LaughEvent.self, from: JSONEncoder().encode(event))
    try expectEqual(decoded, event, "round-tripped event")
    try expectEqual(decoded.detector, .soundAnalysis, "detector survives storage")
}
