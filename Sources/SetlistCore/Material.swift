import Foundation

/// A durable unit of material. The joke is what a comedian owns and reuses;
/// everything else in the model points at one.
public struct Joke: Identifiable, Codable, Equatable, Sendable {
    /// A span of the joke's body the comedian must not paraphrase — the stage
    /// screen highlights these. Offsets are into `body`'s Character view.
    public struct SetupSpan: Codable, Equatable, Sendable {
        public var start: Int
        public var length: Int

        public init(start: Int, length: Int) {
            self.start = start
            self.length = length
        }
    }

    public var id: UUID
    public var title: String
    public var body: String
    /// Spans of `body` that carry the setup the punch depends on.
    public var setups: [SetupSpan]
    /// Alternate tags, delivery notes — the optional text an expanded card shows.
    public var notes: [String]
    public var tags: [String]
    /// Jokes this one calls back to.
    public var callbacks: [UUID]
    /// The comedian's own estimate, in seconds. Unknown stays absent.
    public var estimatedLength: TimeInterval?

    public init(
        id: UUID = UUID(),
        title: String,
        body: String,
        setups: [SetupSpan] = [],
        notes: [String] = [],
        tags: [String] = [],
        callbacks: [UUID] = [],
        estimatedLength: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.setups = setups
        self.notes = notes
        self.tags = tags
        self.callbacks = callbacks
        self.estimatedLength = estimatedLength
    }

    /// The text a setup span covers, or nil when the span falls outside `body`.
    public func setupText(_ span: SetupSpan) -> String? {
        let characters = Array(body)
        guard span.start >= 0, span.length >= 0, span.start + span.length <= characters.count else { return nil }
        return String(characters[span.start ..< (span.start + span.length)])
    }
}

/// An ordered list of jokes planned for a show. Named `SetList` because `Set`
/// is the standard library's.
public struct SetList: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    /// Jokes in performance order. Order is position only — never identity.
    public var jokes: [Joke]

    public init(id: UUID = UUID(), name: String, jokes: [Joke] = []) {
        self.id = id
        self.name = name
        self.jokes = jokes
    }

    /// The planned length of the set: its jokes' estimates summed. A joke with
    /// no estimate contributes nothing rather than a guess.
    public var plannedLength: TimeInterval {
        jokes.reduce(0) { $0 + ($1.estimatedLength ?? 0) }
    }

    public mutating func move(from source: Int, to destination: Int) {
        guard jokes.indices.contains(source), jokes.indices.contains(destination) else { return }
        let joke = jokes.remove(at: source)
        jokes.insert(joke, at: destination)
    }
}

/// What the room was. Every descriptor is independently unknown: an unset one
/// is absent, never a zero or an empty string, so "unknown size, seated" and
/// "0 people, seated" stay different facts.
public struct Audience: Codable, Equatable, Sendable {
    public enum Seating: String, Codable, Sendable { case seated, standing, mixed }
    public enum Service: String, Codable, Sendable { case none, drinks, dinner }
    public enum Crowd: String, Codable, Sendable { case publicRoom, corporate, comics, students, privateEvent }

    public var size: Int?
    public var seating: Seating?
    public var service: Service?
    public var crowd: Crowd?
    /// Whatever the structured fields cannot hold.
    public var note: String?

    public init(
        size: Int? = nil,
        seating: Seating? = nil,
        service: Service? = nil,
        crowd: Crowd? = nil,
        note: String? = nil
    ) {
        self.size = size
        self.seating = seating
        self.service = service
        self.crowd = crowd
        self.note = note
    }
}

/// One performance event, with one recording.
public struct Show: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var venue: String
    public var startedAt: Date
    /// The slot the comedian was given, in seconds.
    public var plannedLength: TimeInterval
    public var audience: Audience
    public var setListID: UUID?

    public init(
        id: UUID = UUID(),
        venue: String,
        startedAt: Date,
        plannedLength: TimeInterval,
        audience: Audience = Audience(),
        setListID: UUID? = nil
    ) {
        self.id = id
        self.venue = venue
        self.startedAt = startedAt
        self.plannedLength = plannedLength
        self.audience = audience
        self.setListID = setListID
    }
}
