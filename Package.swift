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
    ],
    targets: [
        .target(name: "SetlistCore", path: "Sources/SetlistCore"),
        .testTarget(
            name: "SetlistRequirements",
            dependencies: ["SetlistCore"],
            path: "dev/requirements",
            exclude: ["requirements.md", "gate"]
        ),
    ]
)
