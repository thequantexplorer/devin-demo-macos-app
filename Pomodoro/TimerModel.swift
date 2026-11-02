import Foundation
import PomodoroCore

/// Drives a `PomodoroTimer` from the clock and publishes what the UI shows.
@MainActor
final class TimerModel: ObservableObject {
    static let shared = TimerModel(settings: LaunchOptions.settings)

    @Published private(set) var phaseTitle = ""
    @Published private(set) var timeText = ""
    @Published private(set) var isRunning = false
    @Published private(set) var isPausedAtFullLength = true
    @Published private(set) var completedFocusSessions = 0

    private var timer: PomodoroTimer
    private var ticker: Timer?

    init(settings: PomodoroSettings) {
        timer = PomodoroTimer(settings: settings)
        refresh()
        let ticker = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        ticker.tolerance = 0.05
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }

    func startPause() {
        if timer.isRunning {
            timer.pause(at: Date())
        } else {
            timer.start(at: Date())
        }
        refresh()
    }

    func reset() {
        timer.reset()
        refresh()
    }

    func skip() {
        timer.skip()
        refresh()
    }

    private func tick() {
        if timer.tick(at: Date()) {
            Notifier.shared.phaseEnded(movingTo: timer.phase)
        }
        refresh()
    }

    private func refresh() {
        let now = Date()
        update(\.phaseTitle, timer.phase.title)
        update(\.timeText, TimeFormat.clock(timer.remaining(at: now)))
        update(\.isRunning, timer.isRunning)
        update(\.isPausedAtFullLength, timer.isPausedAtFullLength)
        update(\.completedFocusSessions, timer.completedFocusSessions)
    }

    private func update<T: Equatable>(_ keyPath: ReferenceWritableKeyPath<TimerModel, T>, _ value: T) {
        if self[keyPath: keyPath] != value {
            self[keyPath: keyPath] = value
        }
    }
}
