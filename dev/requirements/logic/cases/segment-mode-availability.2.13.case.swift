import Foundation
import SetlistCore

/// 2.13 — The segment-mode switch cannot be turned on while no autodetector is
/// available, and says so rather than silently ignoring the gesture.
let segmentModeAvailability_2_13 = RequirementCase(id: "2.13") {
    let set = SetList(name: "Fri late", jokes: [Joke(title: "Gym induction", body: "…")])

    var phaseA = StageModel(setList: set, plannedLength: 1200)
    try expectEqual(phaseA.segmentMode, .manual, "the switch starts off")
    do {
        try phaseA.setSegmentMode(.autodetect)
        throw RequirementFailure(description: "autodetect was accepted with no detector registered")
    } catch let refusal as SegmentModeRefusal {
        try expectEqual(refusal, .autodetectUnavailable, "refusal reason")
    }
    try expectEqual(phaseA.segmentMode, .manual, "the switch stayed off")

    // The view needs no change once a detector registers.
    var withDetector = StageModel(setList: set, plannedLength: 1200, autodetectAvailable: true)
    try withDetector.setSegmentMode(.autodetect)
    try expectEqual(withDetector.segmentMode, .autodetect, "the switch turns on once a detector exists")
}
