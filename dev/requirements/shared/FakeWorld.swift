import Foundation

/// The one reference instant every case formats and compares against. Nothing
/// under `dev/requirements/` reads the wall clock — a requirement whose result
/// depends on when it ran is not a requirement.
let REFERENCE_NOW = Date(timeIntervalSince1970: 1_754_000_000) // 2025-08-01T00:53:20Z

/// The repository root, derived from this file's own location so a case can
/// read a committed artifact (the app's Info.plist, a sample) without depending
/// on the working directory a runner happened to start in.
let REPO_ROOT: URL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent() // shared
    .deletingLastPathComponent() // requirements
    .deletingLastPathComponent() // dev
    .deletingLastPathComponent() // repo root
