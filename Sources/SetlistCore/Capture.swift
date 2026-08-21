import Foundation

/// Seconds since the capture session started, read off a monotonic source. Card
/// taps and laugh events are both stamped with one, so their interleaving stays
/// well defined across a wall-clock change (requirement 4.4).
public struct CaptureTime: Codable, Equatable, Comparable, Sendable {
    public var seconds: TimeInterval

    public init(_ seconds: TimeInterval) {
        self.seconds = seconds
    }

    public static func < (lhs: CaptureTime, rhs: CaptureTime) -> Bool {
        lhs.seconds < rhs.seconds
    }
}

/// Anything the timeline can order.
public protocol CaptureTimed {
    var at: CaptureTime { get }
}

/// Which detector produced a laugh event. Scores from different detectors are
/// not comparable until a calibration pass exists (decision D3), so the event
/// carries its source rather than defaulting to one.
public enum LaughDetector: String, Codable, Sendable {
    /// On-device SoundAnalysis, live during the set.
    case soundAnalysis
    /// The batch detector in the Phase B pipeline.
    case batch
}

/// A classified span of audience noise.
public struct LaughEvent: Codable, Equatable, Sendable, CaptureTimed {
    public enum Kind: String, Codable, Sendable { case laughter, applause, cheering }

    public var at: CaptureTime
    public var duration: TimeInterval
    public var kind: Kind
    /// The classifier's confidence in `kind`, 0...1.
    public var confidence: Double
    /// Loudness inside the classified window, 0...1.
    public var intensity: Double
    public var detector: LaughDetector

    public init(
        at: CaptureTime,
        duration: TimeInterval,
        kind: Kind,
        confidence: Double,
        intensity: Double,
        detector: LaughDetector
    ) {
        self.at = at
        self.duration = duration
        self.kind = kind
        self.confidence = confidence
        self.intensity = intensity
        self.detector = detector
    }
}

/// How a segment's boundary was decided. Provenance is kept because Phase B
/// proposes boundaries a comedian never tapped.
public enum SegmentProvenance: String, Codable, Sendable {
    case manual
    case detected
}

/// A span of a show's recording bound to a joke. `end` is absent while the
/// segment is still open — absent, never a zero.
public struct Segment: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var jokeID: UUID
    public var start: CaptureTime
    public var end: CaptureTime?
    public var provenance: SegmentProvenance

    public init(
        id: UUID = UUID(),
        jokeID: UUID,
        start: CaptureTime,
        end: CaptureTime? = nil,
        provenance: SegmentProvenance
    ) {
        self.id = id
        self.jokeID = jokeID
        self.start = start
        self.end = end
        self.provenance = provenance
    }

    public var duration: TimeInterval? {
        end.map { $0.seconds - start.seconds }
    }
}

/// A card tap, stamped on the capture clock.
public struct TapEvent: Codable, Equatable, Sendable, CaptureTimed {
    public var at: CaptureTime
    public var jokeID: UUID

    public init(at: CaptureTime, jokeID: UUID) {
        self.at = at
        self.jokeID = jokeID
    }
}

/// One ordering over everything the session recorded.
public enum TimelineEntry: Equatable, Sendable, CaptureTimed {
    case tap(TapEvent)
    case laugh(LaughEvent)

    public var at: CaptureTime {
        switch self {
        case .tap(let event): return event.at
        case .laugh(let event): return event.at
        }
    }
}

/// Taps and laugh events merged onto the one clock they share. Equal stamps
/// keep taps first: a tap is the boundary the laughs after it belong to.
public func timeline(taps: [TapEvent], laughs: [LaughEvent]) -> [TimelineEntry] {
    let entries = taps.map(TimelineEntry.tap) + laughs.map(TimelineEntry.laugh)
    return entries.enumerated().sorted { lhs, rhs in
        if lhs.element.at != rhs.element.at {
            return lhs.element.at < rhs.element.at
        }
        if lhs.element.isTap != rhs.element.isTap {
            return lhs.element.isTap
        }
        return lhs.offset < rhs.offset
    }.map { $0.element }
}

extension TimelineEntry {
    var isTap: Bool {
        if case .tap = self { return true }
        return false
    }
}
