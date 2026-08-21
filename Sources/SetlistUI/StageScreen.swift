#if canImport(SwiftUI)
import SwiftUI
import SetlistCore

/// Everything the stage screen draws, in one value. A screen requirement is a
/// resting state, so the view takes state and draws it — it owns no clock, no
/// audio session and no store.
public struct StageState {
    public var model: StageModel
    public var venue: String
    /// Seconds into the set.
    public var elapsed: TimeInterval
    /// Live laugh level, 0...1. Above `speakOverThreshold` the strip is lit.
    public var laughLevel: Double
    public var isRecording: Bool

    public static let speakOverThreshold = 0.35

    public init(
        model: StageModel,
        venue: String,
        elapsed: TimeInterval,
        laughLevel: Double = 0,
        isRecording: Bool = true
    ) {
        self.model = model
        self.venue = venue
        self.elapsed = elapsed
        self.laughLevel = laughLevel
        self.isRecording = isRecording
    }

    var remaining: TimeInterval {
        Countdown.remaining(plannedLength: model.plannedLength, elapsed: elapsed)
    }

    var liveCard: StageCard? {
        model.cards.first(where: { $0.state == .live })
    }
}

/// The live screen. Portrait, one screenful, no scrolling: a comedian scrolling
/// on stage has already lost the room.
public struct StageScreen: View {
    public var state: StageState
    public var onTapCard: (UUID) -> Void
    public var onSetSegmentMode: (SegmentMode) -> Void

    public init(
        state: StageState,
        onTapCard: @escaping (UUID) -> Void = { _ in },
        onSetSegmentMode: @escaping (SegmentMode) -> Void = { _ in }
    ) {
        self.state = state
        self.onTapCard = onTapCard
        self.onSetSegmentMode = onSetSegmentMode
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            currentJoke
            segmentModeRow
            setListGrid
        }
        .background(Palette.ink)
        .foregroundStyle(Palette.bone)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    if state.isRecording {
                        Circle()
                            .fill(Palette.red)
                            .frame(width: 10, height: 10)
                            .accessibilityLabel("Recording")
                    }
                    Text(state.venue.uppercased())
                        .font(.system(size: 13))
                        .kerning(0.6)
                        .foregroundStyle(Palette.dim)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(Self.countdown(state.remaining))
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                        .foregroundStyle(countdownColour)
                    Text("\(Self.clock(state.elapsed)) / \(Self.clock(state.model.plannedLength))")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Palette.mute)
                }
            }
            pacingBar
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var countdownColour: Color {
        switch Countdown.tone(remaining: state.remaining) {
        case .neutral: return Palette.bone
        case .warning: return Palette.orange
        case .over: return Palette.red
        }
    }

    /// One segment per joke, sized by its estimate: the set's shape, and where
    /// in it the comedian actually is.
    private var pacingBar: some View {
        GeometryReader { proxy in
            HStack(spacing: 3) {
                ForEach(state.model.cards) { card in
                    Rectangle()
                        .fill(paceColour(card.state))
                        .frame(width: paceWidth(card, total: proxy.size.width))
                }
            }
        }
        .frame(height: 7)
    }

    private func paceColour(_ cardState: CardState) -> Color {
        switch cardState {
        case .told: return Palette.green
        case .live: return Palette.orange
        case .queued: return Palette.rule
        }
    }

    private func paceWidth(_ card: StageCard, total: CGFloat) -> CGFloat {
        let weights = state.model.cards.map { $0.joke.estimatedLength ?? 120 }
        let sum = weights.reduce(0, +)
        guard sum > 0 else { return 0 }
        let gaps = CGFloat(max(state.model.cards.count - 1, 0)) * 3
        let available = max(total - gaps, 0)
        return available * CGFloat((card.joke.estimatedLength ?? 120) / sum)
    }

    // MARK: - Current joke

    private var currentJoke: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let card = state.liveCard {
                HStack(alignment: .firstTextBaseline) {
                    Text(card.joke.title)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("on \(Self.clock(card.runTime))")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(Palette.dim)
                }
                Self.body(of: card.joke)
                    .font(.system(size: 25))
                    .lineSpacing(9)
                if !card.joke.tags.isEmpty || !card.joke.callbacks.isEmpty {
                    tags(for: card.joke)
                }
            } else {
                Text("Tap a card to start")
                    .font(.system(size: 25))
                    .foregroundStyle(Palette.dim)
            }
            laughStrip
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.panel)
        .overlay(alignment: .leading) { Rectangle().fill(Palette.orange).frame(width: 6) }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    /// The joke's text with its crucial setups highlighted — the words the
    /// punch depends on, the ones a tired comic paraphrases away.
    static func body(of joke: Joke) -> Text {
        let characters = Array(joke.body)
        let marked = joke.setups
            .filter { $0.start >= 0 && $0.length > 0 && $0.start + $0.length <= characters.count }
            .sorted { $0.start < $1.start }

        var result = Text("")
        var cursor = 0
        for span in marked where span.start >= cursor {
            if span.start > cursor {
                result = result + Text(String(characters[cursor ..< span.start])).foregroundColor(Palette.bone)
            }
            let highlighted = String(characters[span.start ..< (span.start + span.length)])
            result = result + Text(highlighted).foregroundColor(Palette.ink).bold()
            cursor = span.start + span.length
        }
        if cursor < characters.count {
            result = result + Text(String(characters[cursor...])).foregroundColor(Palette.bone)
        }
        return result
    }

    private func tags(for joke: Joke) -> some View {
        HStack(spacing: 8) {
            ForEach(joke.callbacks, id: \.self) { _ in
                tag("callback", accent: Palette.green)
            }
            ForEach(joke.tags, id: \.self) { text in
                tag(text, accent: Palette.dim)
            }
        }
    }

    private func tag(_ text: String, accent: Color) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .overlay(Rectangle().stroke(accent.opacity(0.5), lineWidth: 1))
    }

    /// One bar, lit while the room is louder than the comedian can talk over.
    /// The one thing genuinely hard to judge from behind a mic.
    private var laughStrip: some View {
        Rectangle()
            .fill(state.laughLevel > StageState.speakOverThreshold ? Palette.green : Palette.rule)
            .frame(height: 10)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Segment mode

    private var segmentModeRow: some View {
        HStack(spacing: 13) {
            Toggle("", isOn: Binding(
                get: { state.model.segmentMode == .autodetect },
                set: { onSetSegmentMode($0 ? .autodetect : .manual) }
            ))
            .labelsHidden()
            .disabled(!state.model.autodetectAvailable)
            Text(state.model.segmentMode == .autodetect ? "Autodetect bits" : "Manual switch")
                .font(.system(size: 17))
                .foregroundStyle(state.model.segmentMode == .autodetect ? Palette.green : Palette.dim)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Set list

    private var setListGrid: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("SET LIST · \(state.model.startedCount) / \(state.model.plannedCount)")
                    .font(.system(size: 14))
                    .kerning(0.6)
                Spacer()
                HStack(spacing: 13) {
                    key("told", Palette.green)
                    key("live", Palette.orange)
                    key("queued", Palette.edge)
                }
            }
            .foregroundStyle(Palette.dim)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3),
                spacing: 9
            ) {
                ForEach(state.model.cards) { card in
                    Button { onTapCard(card.id) } label: { cardFace(card) }
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func key(_ label: String, _ colour: Color) -> some View {
        HStack(spacing: 5) {
            Rectangle().fill(colour).frame(width: 10, height: 10)
            Text(label).font(.system(size: 13))
        }
    }

    /// A card carries its joke and how long it ran — never a laugh score.
    /// Requirement 2.7: scores off the stage screen.
    private func cardFace(_ card: StageCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(card.joke.title)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(cardTitleColour(card.state))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Text(cardFootnote(card))
                .font(.system(size: 14, design: card.state == .queued ? .default : .monospaced))
                .foregroundStyle(cardFootnoteColour(card.state))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(cardBackground(card.state))
    }

    private func cardFootnote(_ card: StageCard) -> String {
        switch card.state {
        case .live: return "LIVE · \(Self.clock(card.runTime))"
        case .told: return Self.clock(card.runTime)
        case .queued: return card.joke.estimatedLength.map { "~\(Self.clock($0))" } ?? "—"
        }
    }

    private func cardBackground(_ cardState: CardState) -> Color {
        switch cardState {
        case .told: return Palette.greenDeep
        case .live: return Palette.orange
        case .queued: return Palette.panel
        }
    }

    private func cardTitleColour(_ cardState: CardState) -> Color {
        switch cardState {
        case .told: return Palette.green
        case .live: return Palette.ink
        case .queued: return Palette.bone
        }
    }

    private func cardFootnoteColour(_ cardState: CardState) -> Color {
        switch cardState {
        case .told: return Palette.greenInk
        case .live: return Palette.orangeDeep
        case .queued: return Palette.dim
        }
    }

    // MARK: - Formatting

    /// `m:ss`, the only time format on the screen.
    static func clock(_ seconds: TimeInterval) -> String {
        let whole = Int(seconds.rounded(.down))
        return "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }

    /// The countdown reads as a negative once the slot is over.
    static func countdown(_ remaining: TimeInterval) -> String {
        remaining < 0 ? "+\(clock(-remaining))" : "−\(clock(remaining))"
    }
}
#endif
