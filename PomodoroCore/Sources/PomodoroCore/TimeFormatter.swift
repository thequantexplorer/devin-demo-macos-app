import Foundation

public enum TimeFormatter {
    /// Formats seconds as MM:SS (minutes are not capped, e.g. 100:00).
    /// Fractions round *up*, so the display shows 00:01 until the phase has really run out.
    public static func minutesSeconds(_ seconds: TimeInterval) -> String {
        let total = seconds.isFinite ? max(0, Int(seconds.rounded(.up))) : 0
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
