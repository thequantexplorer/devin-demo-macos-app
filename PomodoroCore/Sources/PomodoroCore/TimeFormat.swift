import Foundation

public enum TimeFormat {
    /// Formats seconds as "MM:SS", for example 1500 -> "25:00".
    /// Partial seconds round up, so the display only shows "00:00" when time is really up.
    public static func clock(_ seconds: TimeInterval) -> String {
        let total = seconds.isFinite ? Int(max(0, seconds.rounded(.up))) : 0
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
