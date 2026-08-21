// swift-tools-version: 5.9
import PackageDescription

// The product's platform-independent core, plus the executable requirements
// that run against it. The iPad app shell itself is an Xcode project under
// `app/` (generated from `app/project.yml`) that consumes this package — a
// SwiftPM package cannot build an iOS application target.
let package = Package(
    name: "Setlist",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "SetlistCore", targets: ["SetlistCore"]),
        .library(name: "SetlistUI", targets: ["SetlistUI"]),
    ],
    targets: [
        .target(name: "SetlistCore", path: "Sources/SetlistCore"),
        // Every file here is behind `#if canImport(SwiftUI)`, so the module is
        // empty rather than broken where SwiftUI does not exist — the Linux
        // lane still builds the package.
        .target(name: "SetlistUI", dependencies: ["SetlistCore"], path: "Sources/SetlistUI"),
        .testTarget(
            name: "SetlistRequirements",
            dependencies: ["SetlistCore", "SetlistUI"],
            path: "dev/requirements",
            exclude: ["README.md", "requirements.md", "gate"]
        ),
    ]
)
