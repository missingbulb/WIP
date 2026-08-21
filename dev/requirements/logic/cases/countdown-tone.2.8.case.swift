import Foundation
import SetlistCore

/// 2.8 — Neutral above three minutes remaining, orange at three minutes or
/// less, red at zero, counting up as a negative after that.
let countdownTone_2_8 = RequirementCase(id: "2.8") {
    try expectEqual(Countdown.remaining(plannedLength: 1200, elapsed: 1122), 78, "remaining time")
    try expectEqual(Countdown.remaining(plannedLength: 1200, elapsed: 1260), -60, "remaining time past the slot")

    try expectEqual(Countdown.tone(remaining: 600), .neutral, "ten minutes left")
    try expectEqual(Countdown.tone(remaining: 181), .neutral, "just above the threshold")
    try expectEqual(Countdown.tone(remaining: 180), .warning, "exactly at the threshold")
    try expectEqual(Countdown.tone(remaining: 78), .warning, "inside the last three minutes")
    try expectEqual(Countdown.tone(remaining: 0), .over, "on the buzzer")
    try expectEqual(Countdown.tone(remaining: -60), .over, "a minute over")
}
