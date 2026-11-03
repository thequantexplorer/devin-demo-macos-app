import Foundation

/// Wraps `PomodoroTimer` with a clock, so callers can tick it from any
/// repeating timer without drift: elapsed time is measured from the clock,
/// not assumed from the tick interval.
public struct PomodoroSession: Sendable {
    public typealias Clock = @Sendable () -> Date

    public private(set) var timer: PomodoroTimer
    private let now: Clock
    private var lastUpdate: Date?

    public init(configuration: PomodoroConfiguration = .standard, now: @escaping Clock = { Date() }) {
        self.timer = PomodoroTimer(configuration: configuration)
        self.now = now
    }

    public mutating func start() {
        timer.start()
        lastUpdate = timer.isRunning ? now() : nil
    }

    public mutating func pause() {
        update()
        timer.pause()
        lastUpdate = nil
    }

    public mutating func toggle() {
        timer.isRunning ? pause() : start()
    }

    public mutating func reset() {
        timer.reset()
        lastUpdate = nil
    }

    public mutating func skip() {
        timer.skip()
        lastUpdate = nil
    }

    /// Applies the time elapsed on the clock since the last update.
    @discardableResult
    public mutating func update() -> [PhaseCompletion] {
        guard timer.isRunning, let last = lastUpdate else { return [] }
        let current = now()
        lastUpdate = current
        return timer.tick(by: current.timeIntervalSince(last))
    }
}
