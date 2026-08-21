#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit

/// One portrait iPad screen, at true 3:4 proportions. Every screen case renders
/// at exactly this size: the requirement is what fits on one screen, so the
/// size is part of the spec rather than a per-case choice.
let SCREEN_SIZE = CGSize(width: 834, height: 1112)

/// Set to refresh rather than compare — how an intended UI change lands, with
/// the new PNGs riding the diff for the owner to approve.
private var isRefreshing: Bool {
    ProcessInfo.processInfo.environment["REFRESH_GOLDENS"] == "1"
}

private let failuresDirectory = REPO_ROOT.appendingPathComponent("dev/requirements/screen/.failures")

/// Renders `view` and compares it, pixel for pixel, with the committed golden.
/// No tolerance: a tolerance is a standing invitation for unreviewed drift.
@MainActor
func expectScreen<V: View>(_ view: V, slug: String, id: String) throws {
    let renderer = ImageRenderer(content: view.frame(width: SCREEN_SIZE.width, height: SCREEN_SIZE.height))
    renderer.scale = 1
    guard let rendered = renderer.uiImage, let actual = rendered.cgImage else {
        throw RequirementFailure(description: "\(slug).\(id): the view did not render")
    }

    let golden = REPO_ROOT.appendingPathComponent("dev/requirements/screen/cases/\(slug).\(id).png")
    if isRefreshing {
        guard let data = rendered.pngData() else {
            throw RequirementFailure(description: "\(slug).\(id): the render did not encode")
        }
        try data.write(to: golden)
        return
    }

    guard let expectedImage = UIImage(contentsOfFile: golden.path)?.cgImage else {
        try write(rendered, named: "\(slug).\(id).actual.png")
        throw RequirementFailure(
            description: "\(slug).\(id): no committed golden. The render is in screen/.failures/ — approve it by refreshing."
        )
    }

    let actualPixels = try pixels(of: actual)
    let expectedPixels = try pixels(of: expectedImage)
    guard actual.width == expectedImage.width, actual.height == expectedImage.height else {
        try write(rendered, named: "\(slug).\(id).actual.png")
        throw RequirementFailure(
            description: "\(slug).\(id): rendered \(actual.width)×\(actual.height), golden is \(expectedImage.width)×\(expectedImage.height)"
        )
    }
    guard actualPixels != expectedPixels else { return }

    let differing = zip(actualPixels, expectedPixels).reduce(into: 0) { $0 += ($1.0 == $1.1 ? 0 : 1) } / 4
    try write(rendered, named: "\(slug).\(id).actual.png")
    throw RequirementFailure(
        description: "\(slug).\(id): \(differing) pixels differ from the golden. The render is in screen/.failures/."
    )
}

private func pixels(of image: CGImage) throws -> [UInt8] {
    let width = image.width
    let height = image.height
    var buffer = [UInt8](repeating: 0, count: width * height * 4)
    guard let context = CGContext(
        data: &buffer,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw RequirementFailure(description: "could not read the render's pixels")
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return buffer
}

/// Failure artifacts go to their own gitignored directory, never beside the
/// goldens, so an actual can never be mistaken for an approved expected.
private func write(_ image: UIImage, named name: String) throws {
    guard let data = image.pngData() else { return }
    try FileManager.default.createDirectory(at: failuresDirectory, withIntermediateDirectories: true)
    try data.write(to: failuresDirectory.appendingPathComponent(name))
}
#endif
