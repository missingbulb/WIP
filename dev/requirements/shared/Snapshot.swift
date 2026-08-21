#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit
import SetlistUI

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
///
/// `region` is the crop: the golden is the smallest surface that proves the
/// leaf, because a reviewer approving one line should be looking at the thing
/// that line claims, not at the whole iPad. Always the composed screen — the
/// crop is taken out of a full render, never by laying an element out alone,
/// which would prove it in a context the product never shows. Passing nil is a
/// deliberate exception, for a leaf that really is about the whole screen.
///
/// `frame` numbers a saga's steps; a screen case leaves it nil and owns one
/// golden named for its leaf alone.
@MainActor
func expectScreen<V: View>(
    _ view: V,
    slug: String,
    id: String,
    region: StageRegion? = nil,
    frame: Int? = nil
) throws {
    let name = frame.map { "\(slug).\(id).step-\(String(format: "%02d", $0))" } ?? "\(slug).\(id)"
    let kind = frame == nil ? "screen" : "saga"

    var measured: [StageRegion: CGRect] = [:]
    let renderer = ImageRenderer(
        content: StageRegionReader(
            content: { view.frame(width: SCREEN_SIZE.width, height: SCREEN_SIZE.height) },
            onMeasure: { measured = $0 }
        )
    )
    renderer.scale = 1
    guard let whole = renderer.uiImage, let wholeImage = whole.cgImage else {
        throw RequirementFailure(description: "\(name): the view did not render")
    }

    let actual = try crop(wholeImage, to: region, measured: measured, name: name)
    let rendered = UIImage(cgImage: actual)

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

/// The region's rect comes from the render that just happened, so a crop can
/// never drift from the layout it was taken out of.
private func crop(
    _ image: CGImage,
    to region: StageRegion?,
    measured: [StageRegion: CGRect],
    name: String
) throws -> CGImage {
    guard let region else { return image }
    guard let rect = measured[region] else {
        throw RequirementFailure(description: "\(name): the screen published no \(region.rawValue) region")
    }
    // A sub-point edge would round the crop differently run to run; growing to
    // whole pixels keeps the golden stable and never loses part of the element.
    let bounds = rect.integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
    guard !bounds.isEmpty, let cropped = image.cropping(to: bounds) else {
        throw RequirementFailure(description: "\(name): the \(region.rawValue) region is \(rect), outside the render")
    }
    return cropped
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
