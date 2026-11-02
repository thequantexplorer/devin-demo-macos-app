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

    /// When the current phase ends. Only set while running.
    private var phaseEnd: Date?
    /// Time left in the current phase. Only meaningful while paused.
    private var pausedRemaining: TimeInterval

    public init(settings: PomodoroSettings = .standard) {
        self.settings = settings
        self.pausedRemaining = settings.duration(of: .focus)
    }

    /// Full length of the current phase.
    public var currentPhaseDuration: TimeInterval {
        settings.duration(of: phase)
    }

    /// True when the timer is paused with the whole current phase still left.
    public var isPausedAtFullLength: Bool {
        !isRunning && pausedRemaining >= currentPhaseDuration
    }

    /// Seconds left in the current phase at `now`.
    public func remaining(at now: Date) -> TimeInterval {
        guard isRunning, let phaseEnd else { return max(0, pausedRemaining) }
        return max(0, phaseEnd.timeIntervalSince(now))
    }

    public mutating func start(at now: Date) {
        guard !isRunning else { return }
        isRunning = true
        phaseEnd = now.addingTimeInterval(pausedRemaining)
    }

    public mutating func pause(at now: Date) {
        guard isRunning else { return }
        pausedRemaining = remaining(at: now)
        isRunning = false
        phaseEnd = nil
    }

    /// Stops the timer and puts the current phase back to its full length.
    public mutating func reset() {
        isRunning = false
        phaseEnd = nil
        pausedRemaining = currentPhaseDuration
    }

    /// Ends the current phase now and moves to the next one, paused.
    public mutating func skip() {
        advancePhase()
        reset()
    }

    /// Call this about once a second while the timer runs.
    /// Returns true when a phase finished and the timer moved to the next phase.
    @discardableResult
    public mutating func tick(at now: Date) -> Bool {
        guard isRunning, var end = phaseEnd else { return false }
        var advanced = false
        while now >= end {
            advancePhase()
            end = end.addingTimeInterval(currentPhaseDuration)
            advanced = true
        }
        phaseEnd = end
        return advanced
    }

    /// The phase that comes after the current one.
    public var nextPhase: Phase {
        switch phase {
        case .focus:
            let every = max(1, settings.focusSessionsBeforeLongBreak)
            return (completedFocusSessions + 1) % every == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    private mutating func advancePhase() {
        let next = nextPhase
        if phase == .focus {
            completedFocusSessions += 1
        }
        phase = next
    }
}
