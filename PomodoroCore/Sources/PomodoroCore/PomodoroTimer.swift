import Foundation

/// A phase that ran out during `tick(by:)`.
public struct PhaseCompletion: Equatable, Sendable {
    /// The phase that ran out.
    public let finished: Phase
    /// The phase that started (running) right after it.
    public let next: Phase
    /// Completed Focus count after the transition.
    public let completedFocusSessions: Int

    public init(finished: Phase, next: Phase, completedFocusSessions: Int) {
        self.finished = finished
        self.next = next
        self.completedFocusSessions = completedFocusSessions
    }
}

/// Pure Pomodoro state machine. Time only moves when `tick(by:)` is called,
/// so it is fully deterministic and needs no real clock.
///
/// Rules:
/// - After a Focus comes a Short break, except after every Nth *completed* Focus
///   (N = `focusSessionsBeforeLongBreak`, default 4), which is followed by a Long break.
/// - After any break comes Focus.
/// - When a phase runs out, the next phase starts right away and keeps running.
/// - `reset()` returns to the full start of the current phase, paused.
/// - `skip()` moves to the start of the next phase, paused.
/// - **Skip does not count a Focus as completed.** Only a Focus that runs out
///   increments `completedFocusSessions`. The phase-after-Focus rule still uses that
///   count, so skipping a Focus always leads to a Short break: a skipped Focus can
///   never be the Nth completed one.
public struct PomodoroTimer: Equatable, Sendable {
    public let configuration: PomodoroConfiguration
    public private(set) var phase: Phase
    public private(set) var remaining: TimeInterval
    public private(set) var isRunning: Bool
    public private(set) var completedFocusSessions: Int

    public init(configuration: PomodoroConfiguration = .standard) {
        self.configuration = configuration
        self.phase = .focus
        self.remaining = configuration.focus
        self.isRunning = false
        self.completedFocusSessions = 0
    }

    // MARK: - Derived state

    /// Full length of the current phase.
    public var phaseDuration: TimeInterval { configuration.duration(of: phase) }

    /// True at the full, untouched start of a phase (not running, nothing elapsed).
    public var isAtPhaseStart: Bool { !isRunning && remaining >= phaseDuration }

    /// True while a phase is under way: running, or paused part-way through.
    public var isUnderWay: Bool { !isAtPhaseStart }

    /// Fraction of the current phase still left, from 1 (start) to 0 (ran out).
    public var fractionRemaining: Double {
        guard phaseDuration > 0 else { return 0 }
        return min(max(remaining / phaseDuration, 0), 1)
    }

    /// Time left formatted as MM:SS.
    public var formattedRemaining: String { TimeFormatter.minutesSeconds(remaining) }

    /// Completed Focus sessions in the current cycle towards the next Long break (0..<N).
    public var completedInCurrentCycle: Int {
        completedFocusSessions % configuration.focusSessionsBeforeLongBreak
    }

    /// The phase that follows the current one if it ran out now.
    public var upcomingPhase: Phase {
        phaseAfter(phase, focusCompleted: true, completedCount: completedFocusSessions + (phase == .focus ? 1 : 0))
    }

    // MARK: - Controls

    public mutating func start() {
        guard remaining > 0 else { return }
        isRunning = true
    }

    public mutating func pause() {
        isRunning = false
    }

    public mutating func toggle() {
        isRunning ? pause() : start()
    }

    /// Back to the full start of the current phase, paused.
    public mutating func reset() {
        remaining = phaseDuration
        isRunning = false
    }

    /// Jump to the start of the next phase, paused. Does not count a Focus as completed.
    public mutating func skip() {
        enter(phaseAfter(phase, focusCompleted: false, completedCount: completedFocusSessions), running: false)
    }

    /// Advance time by `seconds`. Does nothing while paused.
    /// Leftover time carries into the following phases, so a large tick (e.g. after
    /// the Mac wakes from sleep) can complete several phases at once.
    /// - Returns: every phase that ran out, in order.
    @discardableResult
    public mutating func tick(by seconds: TimeInterval) -> [PhaseCompletion] {
        guard isRunning, seconds > 0 else { return [] }
        var left = seconds
        var completions: [PhaseCompletion] = []
        while left > 0 {
            if left < remaining {
                remaining -= left
                break
            }
            left -= remaining
            let finished = phase
            if finished == .focus { completedFocusSessions += 1 }
            let next = phaseAfter(finished, focusCompleted: true, completedCount: completedFocusSessions)
            enter(next, running: true)
            completions.append(PhaseCompletion(finished: finished, next: next, completedFocusSessions: completedFocusSessions))
        }
        return completions
    }

    // MARK: - Private

    /// The phase that follows `phase`. For a Focus, `completedCount` is the completed
    /// Focus count *including* that Focus if it ran out; a skipped Focus never leads to
    /// a Long break because it is not completed.
    private func phaseAfter(_ phase: Phase, focusCompleted: Bool, completedCount: Int) -> Phase {
        switch phase {
        case .focus:
            let n = configuration.focusSessionsBeforeLongBreak
            return focusCompleted && completedCount > 0 && completedCount % n == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    private mutating func enter(_ phase: Phase, running: Bool) {
        self.phase = phase
        remaining = configuration.duration(of: phase)
        isRunning = running
    }
}
