import Foundation

/// Phase lengths (in seconds) and how many completed Focus phases lead to a Long break.
public struct PomodoroConfiguration: Equatable, Sendable {
    public var focus: TimeInterval
    public var shortBreak: TimeInterval
    public var longBreak: TimeInterval
    public var focusSessionsBeforeLongBreak: Int

    public init(
        focus: TimeInterval,
        shortBreak: TimeInterval,
        longBreak: TimeInterval,
        focusSessionsBeforeLongBreak: Int = 4
    ) {
        precondition(focus > 0 && shortBreak > 0 && longBreak > 0, "Durations must be positive")
        precondition(focusSessionsBeforeLongBreak > 0, "focusSessionsBeforeLongBreak must be positive")
        self.focus = focus
        self.shortBreak = shortBreak
        self.longBreak = longBreak
        self.focusSessionsBeforeLongBreak = focusSessionsBeforeLongBreak
    }

    /// 25 / 5 / 15 minutes, Long break after every 4th completed Focus.
    public static let standard = PomodoroConfiguration(focus: 25 * 60, shortBreak: 5 * 60, longBreak: 15 * 60)

    /// Short durations used by UI tests (`-ui-testing`): 5 s / 3 s / 4 s.
    public static let uiTesting = PomodoroConfiguration(focus: 5, shortBreak: 3, longBreak: 4)

    public func duration(of phase: Phase) -> TimeInterval {
        switch phase {
        case .focus: return focus
        case .shortBreak: return shortBreak
        case .longBreak: return longBreak
        }
    }
}
