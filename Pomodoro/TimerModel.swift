import AppKit
import Combine
import PomodoroCore
import SwiftUI

/// Drives a `PomodoroTimer` from the wall clock and publishes what the UI shows.
@MainActor
final class TimerModel: ObservableObject {
    static let shared = TimerModel(settings: LaunchOptions.settings)

    @Published private(set) var timer: PomodoroTimer
    /// Whole seconds left, rounded up, so the view only changes once a second.
    @Published private(set) var displayedRemaining: TimeInterval

    /// Called when a phase runs out, with the phase that just ended and the new one.
    var onPhaseFinished: ((_ finished: Phase, _ next: Phase) -> Void)?

    private var ticker: Timer?
    private var wakeObserver: NSObjectProtocol?

    init(settings: PomodoroSettings) {
        let timer = PomodoroTimer(settings: settings)
        self.timer = timer
        self.displayedRemaining = timer.remaining(at: Date()).rounded(.up)
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    var phase: Phase { timer.phase }
    var isRunning: Bool { timer.isRunning }
    var completed: Int { timer.completedFocusSessions }
    var clock: String { TimeFormat.clock(displayedRemaining) }
    var showsIdleIcon: Bool { timer.isPausedAtFullLength }
    var canReset: Bool { !timer.isPausedAtFullLength }

    /// Fraction of the current phase still left, from 1 (full) to 0.
    var progress: Double {
        let duration = timer.currentPhaseDuration
        guard duration > 0 else { return 0 }
        return min(1, max(0, displayedRemaining / duration))
    }

    var sessionsBeforeLongBreak: Int { max(1, timer.settings.focusSessionsBeforeLongBreak) }

    /// Focus sessions done in the current round towards the long break.
    var sessionsInRound: Int {
        let every = sessionsBeforeLongBreak
        let done = completed % every
        return done == 0 && completed > 0 && phase == .longBreak ? every : done
    }

    func toggle() {
        timer.isRunning ? pause() : start()
    }

    func start() {
        timer.start(at: Date())
        startTicker()
        refresh(animation: nil)
    }

    func pause() {
        timer.pause(at: Date())
        stopTicker()
        refresh(animation: nil)
    }

    func reset() {
        timer.reset()
        stopTicker()
        refresh(animation: .easeOut(duration: 0.25))
    }

    func skip() {
        timer.skip()
        stopTicker()
        refresh(animation: .easeOut(duration: 0.25))
    }

    private func tick() {
        guard timer.isRunning else { return }
        let before = timer.phase
        var next = timer
        if next.tick(at: Date()) {
            withAnimation(.easeOut(duration: 0.25)) { timer = next }
            onPhaseFinished?(before, next.phase)
            refresh(animation: .easeOut(duration: 0.25))
        } else {
            refresh(animation: .linear(duration: 1))
        }
    }

    private func refresh(animation: Animation?) {
        let value = timer.remaining(at: Date()).rounded(.up)
        guard value != displayedRemaining else { return }
        withAnimation(animation) { displayedRemaining = value }
    }

    private func startTicker() {
        guard ticker == nil else { return }
        let ticker = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        ticker.tolerance = 0.05
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}
