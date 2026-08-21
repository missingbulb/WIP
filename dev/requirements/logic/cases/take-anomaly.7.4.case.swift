import Foundation
import SetlistCore

/// 7.4 — A take is flagged anomalous when its peak laugh duration falls at
/// least two standard deviations below the mean of the joke's other takes, and
/// never when fewer than three other takes exist.
let takeAnomaly_7_4 = RequirementCase(id: "7.4") {
    let joke = UUID()
    func take(_ peak: TimeInterval) -> Take {
        Take(jokeID: joke, showID: UUID(), peakLaughDuration: peak)
    }

    // The mockup's row: four healthy takes and the corporate dinner gig.
    let others = [take(4.9), take(3.6), take(4.1), take(2.1)]
    let corporate = take(0.4)

    guard let deviation = TakeAnomaly.deviation(of: corporate, amongOthers: others) else {
        throw RequirementFailure(description: "no deviation computed for a take with four comparisons")
    }
    try expect(deviation >= 2.0, "the cold take is \(deviation)σ below the rest, expected at least 2")
    try expect(TakeAnomaly.isAnomalous(corporate, amongOthers: others), "the cold take is flagged")
    try expect(!TakeAnomaly.isAnomalous(take(3.6), amongOthers: others), "an ordinary take is not flagged")

    // Two comparisons is not a norm — a comic's second gig must not flag their
    // first as an anomaly.
    try expect(
        !TakeAnomaly.isAnomalous(corporate, amongOthers: [take(4.9), take(3.6)]),
        "too few comparison takes to flag anything"
    )
    try expectNil(TakeAnomaly.deviation(of: corporate, amongOthers: [take(4.9), take(3.6)]), "deviation of too few takes")

    // Identical comparisons have no spread to deviate from.
    try expectNil(
        TakeAnomaly.deviation(of: corporate, amongOthers: [take(4.0), take(4.0), take(4.0)]),
        "deviation with zero spread"
    )
}
