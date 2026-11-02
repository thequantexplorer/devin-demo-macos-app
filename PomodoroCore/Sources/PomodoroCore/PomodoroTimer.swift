import Foundation

public enum Phase: String, Equatable {
    case focus
    case shortBreak
    case longBreak

    public var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short break"
        case .longBreak: return "Long break"
        }
    }
}

public struct PomodoroSettings: Equatable {
    public var focus: TimeInterval
    public var shortBreak: TimeInterval
    public var longBreak: TimeInterval
    public var focusSessionsBeforeLongBreak: Int

    public init(
        focus: TimeInterval = 25 * 60,
        shortBreak: TimeInterval = 5 * 60,
        longBreak: TimeInterval = 15 * 60,
        focusSessionsBeforeLongBreak: Int = 4
    ) {
        self.focus = focus
        self.shortBreak = shortBreak
        self.longBreak = longBreak
        self.focusSessionsBeforeLongBreak = focusSessionsBeforeLongBreak
    }

    public static let standard = PomodoroSettings()

    public func duration(of phase: Phase) -> TimeInterval {
        switch phase {
        case .focus: return focus
        case .shortBreak: return shortBreak
        case .longBreak: return longBreak
        }
    }
}

/// The timer logic for the menu bar app. It never reads the clock itself:
/// callers pass `now` in, so tests are fast and deterministic.
/// The rules are in docs/spec.md.
public struct PomodoroTimer {
    public let settings: PomodoroSettings
    public private(set) var phase: Phase = .focus
    public private(set) var isRunning = false
    public private(set) var completedFocusSessions = 0

    public init(settings: PomodoroSettings = .standard) {
        self.settings = settings
    }

    /// Seconds left in the current phase at `now`.
    public func remaining(at now: Date) -> TimeInterval {
        // TODO: not implemented yet.
        return 0
    }

    public mutating func start(at now: Date) {
        // TODO: not implemented yet.
    }

    public mutating func pause(at now: Date) {
        // TODO: not implemented yet.
    }

    /// Stops the timer and puts the current phase back to its full length.
    public mutating func reset() {
        // TODO: not implemented yet.
    }

    /// Ends the current phase now and moves to the next one, paused.
    public mutating func skip() {
        // TODO: not implemented yet.
    }

    /// Call this about once a second while the timer runs.
    /// Returns true when a phase finished and the timer moved to the next phase.
    @discardableResult
    public mutating func tick(at now: Date) -> Bool {
        // TODO: not implemented yet.
        return false
    }
}
