import Foundation

/// Where the library lives between launches. Phase A keeps everything on the
/// iPad, so the only implementation writes a file inside the app's own
/// container — a location the user can delete by deleting the app.
public protocol LibraryStore {
    func load() throws -> Library
    func save(_ library: Library) throws
}

public struct FileLibraryStore: LibraryStore {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    /// The store's home inside a container directory. Named, not defaulted, so
    /// a caller cannot accidentally write outside the container.
    public static func inContainer(_ container: URL) -> FileLibraryStore {
        FileLibraryStore(url: container.appendingPathComponent("library.json"))
    }

    public func load() throws -> Library {
        guard FileManager.default.fileExists(atPath: url.path) else { return Library() }
        return try JSONDecoder().decode(Library.self, from: Data(contentsOf: url))
    }

    public func save(_ library: Library) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(library)
        // Atomic: a set half-written while the app is killed on stage would
        // lose the material, and material loss is the one unforgivable bug.
        try data.write(to: url, options: .atomic)
    }
}
