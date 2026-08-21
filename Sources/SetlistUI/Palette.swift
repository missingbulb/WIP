#if canImport(SwiftUI)
import SwiftUI

/// The stage palette from the mockups: dark enough for a club, warm enough not
/// to read as a terminal. Told is green, live is orange, over-time is red — the
/// three states a comedian reads at a glance from behind a mic.
enum Palette {
    static let ink = Color(red: 0.063, green: 0.055, blue: 0.043)
    static let panel = Color(red: 0.110, green: 0.094, blue: 0.075)
    static let rule = Color(red: 0.149, green: 0.133, blue: 0.110)
    static let edge = Color(red: 0.227, green: 0.216, blue: 0.200)
    static let mute = Color(red: 0.431, green: 0.408, blue: 0.373)
    static let dim = Color(red: 0.541, green: 0.514, blue: 0.471)
    static let bone = Color(red: 0.910, green: 0.890, blue: 0.855)
    static let green = Color(red: 0.0, green: 0.851, blue: 0.639)
    static let greenDeep = Color(red: 0.0, green: 0.239, blue: 0.180)
    static let greenInk = Color(red: 0.0, green: 0.659, blue: 0.494)
    static let orange = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let orangeDeep = Color(red: 0.420, green: 0.239, blue: 0.0)
    static let red = Color(red: 1.0, green: 0.231, blue: 0.188)
}
#endif
