#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit

/// One portrait iPad screen, at true 3:4 proportions. Every screen case renders
/// at exactly this size: the requirement is what fits on one screen, so the
/// size is part of the spec rather than a per-case choice.
let SCREEN_SIZE = CGSize(width: 834, height: 1112)

/// Refresh rather than compare — how an intended UI change lands, with the new
/// PNGs riding the diff for the owner to approve. A file rather than an
/// environment variable: xcodebuild does not carry one into a hostless test
/// bundle's process, and a refresh that silently did not happen is worse than
/// no refresh at all.
var isRefreshingGoldens: Bool {
    FileManager.default.fileExists(atPath: REFRESH_MARKER.path)
}

private let REFRESH_MARKER = REPO_ROOT.appendingPathComponent("dev/requirements/screen/.refresh")

private let failuresDirectory = REPO_ROOT.appendingPathComponent("dev/requirements/.failures")

/// Renders `view` and compares it, pixel for pixel, with the committed golden.
/// No tolerance: a tolerance is a standing invitation for unreviewed drift.
/// `frame` numbers a saga's steps; a screen case leaves it nil and owns one
/// golden named for its leaf alone.
@MainActor
func expectScreen<V: View>(_ view: V, slug: String, id: String, frame: Int? = nil) throws {
    let name = frame.map { "\(slug).\(id).step-\(String(format: "%02d", $0))" } ?? "\(slug).\(id)"
    let kind = frame == nil ? "screen" : "saga"
    let renderer = ImageRenderer(content: view.frame(width: SCREEN_SIZE.width, height: SCREEN_SIZE.height))
    renderer.scale = 1
    guard let rendered = renderer.uiImage, let actual = rendered.cgImage else {
        throw RequirementFailure(description: "\(name): the view did not render")
    }

    let golden = REPO_ROOT.appendingPathComponent("dev/requirements/\(kind)/cases/\(name).png")
    if isRefreshingGoldens {
        guard let data = rendered.pngData() else {
            throw RequirementFailure(description: "\(name): the render did not encode")
        }
        try data.write(to: golden)
        return
    }

    guard let expectedImage = UIImage(contentsOfFile: golden.path)?.cgImage else {
        try write(rendered, named: "\(name).actual.png")
        throw RequirementFailure(
            description: "\(name): no committed golden. The render is in .failures/ — approve it by refreshing."
        )
    }

    let actualPixels = try pixels(of: actual)
    let expectedPixels = try pixels(of: expectedImage)
    guard actual.width == expectedImage.width, actual.height == expectedImage.height else {
        try write(rendered, named: "\(name).actual.png")
        throw RequirementFailure(
            description: "\(name): rendered \(actual.width)×\(actual.height), golden is \(expectedImage.width)×\(expectedImage.height)"
        )
    }
    guard actualPixels != expectedPixels else { return }

    let differing = zip(actualPixels, expectedPixels).reduce(into: 0) { $0 += ($1.0 == $1.1 ? 0 : 1) } / 4
    try write(rendered, named: "\(name).actual.png")
    throw RequirementFailure(
        description: "\(name): \(differing) pixels differ from the golden. The render is in .failures/."
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
