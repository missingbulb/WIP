import Foundation

/// How bit boundaries are decided during a set.
public enum SegmentMode: String, Codable, Sendable {
    /// The comedian taps cards to mark boundaries.
    case manual
    /// Boundaries are inferred from the audio.
    case autodetect
}

/// Why turning the segment-mode switch on did not take.
public enum SegmentModeRefusal: Error, Equatable, Sendable {
    /// No detector is registered, so autodetect would guess in silence.
    case autodetectUnavailable
}

/// A joke's state in the set list.
public enum CardState: String, Codable, Equatable, Sendable {
    case queued
    case live
    case told
}

/// One card in the 3-column grid. Deliberately carries no laugh data:
/// requirement 2.7 keeps scores off the stage screen, and a field that does not
/// exist cannot leak into a layout later.
public struct StageCard: Identifiable, Equatable, Sendable {
    public var id: UUID { joke.id }
    public var joke: Joke
    public var state: CardState
    /// How long this joke has run so far, across all of its segments.
    public var runTime: TimeInterval

    public init(joke: Joke, state: CardState = .queued, runTime: TimeInterval = 0) {
        self.joke = joke
        self.state = state
        self.runTime = runTime
    }
}

/// What a card tap did.
public enum TapOutcome: Equatable, Sendable {
    /// The tapped joke is now live; the previous one's segment closed.
    case switched(to: UUID)
    /// The tapped joke was already live. Nothing changed.
    case ignored
}

/// The live screen's state machine: the set list, which joke is running, and
/// the segments the taps produce.
public struct StageModel {
    public private(set) var cards: [StageCard]
    public private(set) var segments: [Segment]
    /// Registered when a detector exists; false through Phase A.
    public let autodetectAvailable: Bool
    public private(set) var segmentMode: SegmentMode
    /// The slot, in seconds.
    public let plannedLength: TimeInterval

    public init(setList: SetList, plannedLength: TimeInterval, autodetectAvailable: Bool = false) {
        self.cards = setList.jokes.map { StageCard(joke: $0) }
        self.segments = []
        self.autodetectAvailable = autodetectAvailable
        self.segmentMode = .manual
        self.plannedLength = plannedLength
    }

    public var liveJokeID: UUID? {
        cards.first { $0.state == .live }?.id
    }

    /// Jokes started out of jokes planned — the set-list header's count. A joke
    /// re-opened after being told still counts once.
    public var startedCount: Int {
        Set(segments.map(\.jokeID)).count
    }

    public var plannedCount: Int { cards.count }

    /// Tapping a card marks the start of that joke (requirements 3.1–3.3, 3.6).
    @discardableResult
    public mutating func tapCard(jokeID: UUID, at time: CaptureTime) -> TapOutcome {
        guard let index = cards.firstIndex(where: { $0.id == jokeID }) else { return .ignored }
        if cards[index].state == .live { return .ignored }

        closeOpenSegment(at: time)
        segments.append(Segment(jokeID: jokeID, start: time, provenance: .manual))
        cards[index].state = .live
        return .switched(to: jokeID)
    }

    /// Ends the set: the joke still running gets its closing boundary.
    public mutating func endSet(at time: CaptureTime) {
        closeOpenSegment(at: time)
    }

    /// The segment-mode switch. Refuses rather than silently staying off, so
    /// the switch never lies about what the app is doing (requirement 2.13).
    public mutating func setSegmentMode(_ mode: SegmentMode) throws {
        if mode == .autodetect && !autodetectAvailable {
            throw SegmentModeRefusal.autodetectUnavailable
        }
        segmentMode = mode
    }

    private mutating func closeOpenSegment(at time: CaptureTime) {
        guard let openIndex = segments.lastIndex(where: { $0.end == nil }) else { return }
        segments[openIndex].end = time
        let closed = segments[openIndex]
        if let cardIndex = cards.firstIndex(where: { $0.id == closed.jokeID }) {
            cards[cardIndex].state = .told
            cards[cardIndex].runTime += closed.duration ?? 0
        }
    }
}
