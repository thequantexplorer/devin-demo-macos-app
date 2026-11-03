import Combine
import Foundation
import PomodoroCore
import SwiftUI

/// App-side owner of the Pomodoro session: drives it from a 1 s timer and
/// forwards phase completions to notifications.
@MainActor
final class TimerModel: ObservableObject {
    static let shared = TimerModel(configuration: LaunchOptions.isUITesting ? .uiTesting : .standard)

    @Published private(set) var session: PomodoroSession
    private var ticker: Timer?

    var timer: PomodoroTimer { session.timer }

    init(configuration: PomodoroConfiguration) {
        session = PomodoroSession(configuration: configuration)
    }

    func toggle() {
        withAnimation(.easeInOut(duration: 0.2)) { session.toggle() }
        syncTicker()
    }

    func reset() {
        withAnimation(.easeInOut(duration: 0.25)) { session.reset() }
        syncTicker()
    }

    func skip() {
        withAnimation(.easeInOut(duration: 0.25)) { session.skip() }
        syncTicker()
    }

    private func tick() {
        let completions = session.update()
        if let last = completions.last {
            NotificationService.shared.postCompletion(last, configuration: timer.configuration)
        }
    }

    private func syncTicker() {
        guard timer.isRunning else {
            ticker?.invalidate()
            ticker = nil
            return
        }
        guard ticker == nil else { return }
        let ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        ticker.tolerance = 0.05
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }
}
