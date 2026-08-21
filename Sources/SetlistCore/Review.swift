import Foundation

/// One performance of one joke: what screen 2 compares.
public struct Take: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var jokeID: UUID
    public var showID: UUID
    /// The longest laugh this take drew, in seconds — the take's headline number.
    public var peakLaughDuration: TimeInterval

    public init(id: UUID = UUID(), jokeID: UUID, showID: UUID, peakLaughDuration: TimeInterval) {
        self.id = id
        self.jokeID = jokeID
        self.showID = showID
        self.peakLaughDuration = peakLaughDuration
    }
}

/// The anomaly rule behind the mockup's "2.4σ below the rest" flag.
public enum TakeAnomaly {
    /// How far below the rest a take must fall to be flagged.
    public static let sigmaThreshold = 2.0
    /// Fewer comparison takes than this and there is no norm to deviate from.
    public static let minimumComparisonTakes = 3

    /// How many standard deviations below the other takes' mean this take sits.
    /// Nil when there are too few other takes, or when they are all identical
    /// and there is no spread to measure against.
    public static func deviation(of take: Take, amongOthers others: [Take]) -> Double? {
        guard others.count >= minimumComparisonTakes else { return nil }
        let values = others.map(\.peakLaughDuration)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count - 1)
        let sigma = variance.squareRoot()
        guard sigma > 0 else { return nil }
        return (mean - take.peakLaughDuration) / sigma
    }

    public static func isAnomalous(_ take: Take, amongOthers others: [Take]) -> Bool {
        guard let deviation = deviation(of: take, amongOthers: others) else { return false }
        return deviation >= sigmaThreshold
    }
}

/// The countdown's colour. A helper, not the dominant element — it changes
/// colour rather than size (requirement 2.9).
public enum CountdownTone: String, Equatable, Sendable {
    case neutral
    case warning
    case over
}

public enum Countdown {
    /// Remaining time at which the countdown turns orange.
    public static let warningThreshold: TimeInterval = 180

    /// Remaining seconds; negative once the slot is over.
    public static func remaining(plannedLength: TimeInterval, elapsed: TimeInterval) -> TimeInterval {
        plannedLength - elapsed
    }

    public static func tone(remaining: TimeInterval) -> CountdownTone {
        if remaining <= 0 { return .over }
        if remaining <= warningThreshold { return .warning }
        return .neutral
    }
}
