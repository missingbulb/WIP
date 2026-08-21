import Foundation
import SetlistCore

/// 1.5 — A show carries venue, start time, planned set length and structured
/// audience descriptors, each independently unknown.
let audienceDescriptors_1_5 = RequirementCase(id: "1.5") {
    let show = Show(
        venue: "Corp gig, Leith",
        startedAt: REFERENCE_NOW,
        plannedLength: 1200,
        audience: Audience(size: 80, seating: .seated, service: .dinner, crowd: .corporate)
    )
    try expectEqual(show.venue, "Corp gig, Leith", "venue")
    try expectEqual(show.startedAt, REFERENCE_NOW, "start time")
    try expectEqual(show.plannedLength, 1200, "planned length")
    try expectEqual(show.audience.size, 80, "audience size")
    try expectEqual(show.audience.seating, .seated, "seating")
    try expectEqual(show.audience.service, .dinner, "service")
    try expectEqual(show.audience.crowd, .corporate, "crowd")

    // Each descriptor is independently unknown…
    let partial = Audience(seating: .standing)
    try expectNil(partial.size, "unknown size")
    try expectEqual(partial.seating, .standing, "known seating beside an unknown size")

    // …and unknown is not a zero: both states survive a round-trip distinctly.
    let empty = try JSONDecoder().decode(Audience.self, from: Data("{}".utf8))
    try expectNil(empty.size, "absent size decodes as unknown")
    let zero = try JSONDecoder().decode(Audience.self, from: Data(#"{"size":0}"#.utf8))
    try expectEqual(zero.size, 0, "a real zero decodes as zero")
}
