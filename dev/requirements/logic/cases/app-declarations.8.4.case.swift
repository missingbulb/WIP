import Foundation

/// 8.4 — The app declares a microphone usage description and the background-
/// audio mode, and declares no other background mode.
///
/// App Review guideline 2.5.14 and decision "record through a locked screen"
/// both live in the shipped Info.plist, so the plist is what this reads.
let appDeclarations_8_4 = RequirementCase(id: "8.4") {
    let plistURL = REPO_ROOT.appendingPathComponent("app/Setlist/Info.plist")
    let data = try Data(contentsOf: plistURL)
    guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
        throw RequirementFailure(description: "app/Setlist/Info.plist is not a dictionary")
    }

    let microphone = plist["NSMicrophoneUsageDescription"] as? String
    try expect(microphone?.isEmpty == false, "NSMicrophoneUsageDescription is missing or empty")

    let modes = plist["UIBackgroundModes"] as? [String] ?? []
    try expectEqual(modes, ["audio"], "UIBackgroundModes")
}
