import Foundation
import SetlistCore

/// 1.6 — The library survives app relaunch: jokes, sets and shows written in
/// one session are read back in the next.
let librarySurvivesRelaunch_1_6 = RequirementCase(id: "1.6") {
    let container = FileManager.default.temporaryDirectory
        .appendingPathComponent("setlist-1.6-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: container) }

    let joke = Joke(title: "Airport security", body: "…", estimatedLength: 150)
    let set = SetList(name: "Fri late", jokeIDs: [joke.id])
    let show = Show(
        venue: "The Stand",
        startedAt: REFERENCE_NOW,
        plannedLength: 1200,
        audience: Audience(size: 80, seating: .standing),
        setListID: set.id
    )
    let library = Library(jokes: [joke], sets: [set], shows: [show])

    try FileLibraryStore.inContainer(container).save(library)

    // A second store over the same container is the next launch: nothing is
    // carried in memory between them.
    let relaunched = try FileLibraryStore.inContainer(container).load()
    try expectEqual(relaunched, library, "the library read back after a relaunch")
    try expectEqual(relaunched.jokes(of: relaunched.sets[0]).map(\.title), ["Airport security"], "the set still resolves")

    // A first launch, with nothing written yet, is an empty library rather than
    // an error the comedian has to dismiss before their set.
    let fresh = FileManager.default.temporaryDirectory
        .appendingPathComponent("setlist-1.6-fresh-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: fresh) }
    try expectEqual(try FileLibraryStore.inContainer(fresh).load(), Library(), "a first launch")
}
