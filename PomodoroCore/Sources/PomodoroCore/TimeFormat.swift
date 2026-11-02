import Foundation

public enum TimeFormat {
    /// Formats seconds as "MM:SS", for example 1500 -> "25:00".
    /// Partial seconds round up, so the display only shows "00:00" when time is really up.
    public static func clock(_ seconds: TimeInterval) -> String {
        // TODO: not implemented yet.
        return ""
    }
}
