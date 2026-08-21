#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit
import SetlistCore
import SetlistUI

/// One beat of a story: what the comedian does, and the caption that narrates
/// it. The caption is written in user terms, because it is what surfaces in the
/// spec's gallery beneath the frame it labels.
struct SagaStep {
    let caption: String
    let act: (inout StageState) -> Void

    init(_ caption: String, _ act: @escaping (inout StageState) -> Void) {
        self.caption = caption
        self.act = act
    }
}

/// A saga proves what a single frame cannot: what arriving, tapping or time
/// passing *changes*. Each step drives the same real screen every other kind
/// renders, and one frame is captured after each — never a slideshow of
/// hand-arranged states.
func sagaCase(
    id: String,
    slug: String,
    from initial: @escaping () -> StageState,
    steps: [SagaStep]
) -> RequirementCase {
    RequirementCase(id: id) {
        try MainActor.assumeIsolated {
            var state = initial()
            var captions: [String] = []
            for (index, step) in steps.enumerated() {
                step.act(&state)
                try expectScreen(
                    StageScreen(state: state),
                    slug: slug,
                    id: id,
                    frame: index + 1
                )
                captions.append(step.caption)
            }
            try writeCaptions(captions, slug: slug, id: id)
        }
    }
}

/// The captions ride beside the frames as generated data: the gallery needs
/// them to label the strip, and Markdown is not a place to hand-maintain a
/// list that must stay in step with the frames.
private func writeCaptions(_ captions: [String], slug: String, id: String) throws {
    let url = REPO_ROOT.appendingPathComponent("dev/requirements/saga/cases/\(slug).\(id).captions.json")
    let data = try JSONSerialization.data(withJSONObject: captions, options: [.prettyPrinted, .withoutEscapingSlashes])
    let rendered = String(decoding: data, as: UTF8.self) + "\n"

    guard !isRefreshingGoldens else {
        try rendered.write(to: url, atomically: true, encoding: .utf8)
        return
    }
    let committed = try? String(contentsOf: url, encoding: .utf8)
    guard committed == rendered else {
        throw RequirementFailure(
            description: "\(slug).\(id): the captions beside the frames are out of date — refresh"
        )
    }
}
#endif
