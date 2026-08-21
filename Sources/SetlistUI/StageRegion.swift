#if canImport(SwiftUI)
import SwiftUI

/// The parts of the stage screen a requirement can be about. A leaf that
/// asserts one element is proved by a picture of that element, not by the whole
/// iPad: a reviewer approving a spec should be looking at the thing the line
/// claims. The screen names its own regions here so a case can ask for one
/// without knowing any coordinates.
public enum StageRegion: String, Hashable, Sendable, CaseIterable {
    /// The recording dot and the room's name.
    case venue
    /// Countdown, elapsed and planned, together.
    case clocks
    case pacingBar
    /// The whole current-joke panel.
    case currentJoke
    /// The joke's title and how long it has been running.
    case jokeTitleRow
    case jokeBody
    case jokeTags
    case laughStrip
    case segmentMode
    /// "SET LIST · n / n".
    case setListCount
    /// The told / live / queued key.
    case setListKey
    /// The nine cards.
    case grid
}

/// Where each named region ended up, in the coordinate space of whatever is
/// reading the preference.
struct StageRegionBounds: PreferenceKey {
    static var defaultValue: [StageRegion: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [StageRegion: Anchor<CGRect>],
        nextValue: () -> [StageRegion: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, later in later }
    }
}

extension View {
    /// Publishes this view's bounds under `region`, so a snapshot can be
    /// cropped to it. Costs nothing at runtime — nothing in the app reads the
    /// preference.
    ///
    /// Transforms rather than sets: setting the preference would replace
    /// whatever the view's children had already published, so a region drawn
    /// around a panel would erase every region inside it.
    func stageRegion(_ region: StageRegion) -> some View {
        transformAnchorPreference(key: StageRegionBounds.self, value: .bounds) { regions, anchor in
            regions[region] = anchor
        }
    }
}

/// Reads the regions a rendered screen published. Kept beside the enum because
/// it is the other half of the same contract: the screen publishes, the
/// snapshot harness crops.
public struct StageRegionReader<Content: View>: View {
    private let content: Content
    private let onMeasure: ([StageRegion: CGRect]) -> Void

    public init(@ViewBuilder content: () -> Content, onMeasure: @escaping ([StageRegion: CGRect]) -> Void) {
        self.content = content()
        self.onMeasure = onMeasure
    }

    public var body: some View {
        content.overlayPreferenceValue(StageRegionBounds.self) { anchors in
            GeometryReader { proxy in
                measure(anchors, in: proxy)
            }
        }
    }

    /// The measurement happens while the renderer lays the tree out, which is
    /// the only moment the geometry exists — so it reports from inside the
    /// body rather than from an appearance callback the renderer never makes.
    private func measure(_ anchors: [StageRegion: Anchor<CGRect>], in proxy: GeometryProxy) -> Color {
        onMeasure(anchors.mapValues { proxy[$0] })
        return .clear
    }
}
#endif
