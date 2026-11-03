import XCTest
@testable import PomodoroCore

final class PomodoroTimerTests: XCTestCase {
    private let standard = PomodoroConfiguration.standard

    /// Runs the current phase out completely.
    private func finishPhase(_ timer: inout PomodoroTimer) -> [PhaseCompletion] {
        if !timer.isRunning { timer.start() }
        return timer.tick(by: timer.remaining)
    }

    // MARK: Initial state

    func testInitialState() {
        let timer = PomodoroTimer()
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.remaining, 25 * 60)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.completedFocusSessions, 0)
        XCTAssertTrue(timer.isAtPhaseStart)
        XCTAssertFalse(timer.isUnderWay)
        XCTAssertEqual(timer.formattedRemaining, "25:00")
        XCTAssertEqual(timer.fractionRemaining, 1)
    }

    func testStandardDurations() {
        XCTAssertEqual(standard.duration(of: .focus), 1500)
        XCTAssertEqual(standard.duration(of: .shortBreak), 300)
        XCTAssertEqual(standard.duration(of: .longBreak), 900)
        XCTAssertEqual(standard.focusSessionsBeforeLongBreak, 4)
    }

    func testUITestingDurations() {
        let config = PomodoroConfiguration.uiTesting
        XCTAssertEqual(config.focus, 5)
        XCTAssertEqual(config.shortBreak, 3)
        XCTAssertEqual(config.longBreak, 4)
    }

    func testPhaseTitles() {
        XCTAssertEqual(Phase.focus.title, "Focus")
        XCTAssertEqual(Phase.shortBreak.title, "Short break")
        XCTAssertEqual(Phase.longBreak.title, "Long break")
        XCTAssertFalse(Phase.focus.isBreak)
        XCTAssertTrue(Phase.shortBreak.isBreak)
        XCTAssertTrue(Phase.longBreak.isBreak)
    }

    // MARK: Start / pause / resume

    func testTickDoesNothingWhilePaused() {
        var timer = PomodoroTimer()
        XCTAssertEqual(timer.tick(by: 10), [])
        XCTAssertEqual(timer.remaining, 1500)
        XCTAssertTrue(timer.isAtPhaseStart)
    }

    func testStartAndTick() {
        var timer = PomodoroTimer()
        timer.start()
        XCTAssertTrue(timer.isRunning)
        XCTAssertTrue(timer.isUnderWay)
        XCTAssertFalse(timer.isAtPhaseStart)
        timer.tick(by: 1)
        XCTAssertEqual(timer.remaining, 1499)
        XCTAssertEqual(timer.formattedRemaining, "24:59")
    }

    func testPauseAndResume() {
        var timer = PomodoroTimer()
        timer.start()
        timer.tick(by: 60)
        timer.pause()
        XCTAssertFalse(timer.isRunning)
        XCTAssertTrue(timer.isUnderWay, "Paused mid-phase is still under way")
        timer.tick(by: 100)
        XCTAssertEqual(timer.remaining, 1440, "Paused timer must not move")
        timer.start()
        timer.tick(by: 40)
        XCTAssertEqual(timer.remaining, 1400)
        XCTAssertEqual(timer.formattedRemaining, "23:20")
    }

    func testToggle() {
        var timer = PomodoroTimer()
        timer.toggle()
        XCTAssertTrue(timer.isRunning)
        timer.toggle()
        XCTAssertFalse(timer.isRunning)
    }

    func testZeroOrNegativeTickIsIgnored() {
        var timer = PomodoroTimer()
        timer.start()
        XCTAssertEqual(timer.tick(by: 0), [])
        XCTAssertEqual(timer.tick(by: -5), [])
        XCTAssertEqual(timer.remaining, 1500)
    }

    // MARK: Reset

    func testResetReturnsToStartOfCurrentPhaseAndPauses() {
        var timer = PomodoroTimer()
        timer.start()
        timer.tick(by: 125)
        timer.reset()
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.remaining, 1500)
        XCTAssertFalse(timer.isRunning)
        XCTAssertTrue(timer.isAtPhaseStart)
    }

    func testResetDuringBreakStaysInBreak() {
        var timer = PomodoroTimer()
        _ = finishPhase(&timer)
        XCTAssertEqual(timer.phase, .shortBreak)
        timer.tick(by: 30)
        timer.reset()
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.remaining, 300)
        XCTAssertEqual(timer.completedFocusSessions, 1, "Reset keeps the completed count")
    }

    // MARK: Skip

    func testSkipFocusGoesToShortBreakPausedWithoutCounting() {
        var timer = PomodoroTimer()
        timer.start()
        timer.tick(by: 10)
        timer.skip()
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.remaining, 300)
        XCTAssertFalse(timer.isRunning)
        XCTAssertTrue(timer.isAtPhaseStart)
        XCTAssertEqual(timer.completedFocusSessions, 0, "Skip does not count a Focus as completed")
    }

    func testSkipBreakGoesToFocusPaused() {
        var timer = PomodoroTimer()
        timer.skip()
        timer.start()
        timer.skip()
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.remaining, 1500)
        XCTAssertFalse(timer.isRunning)
    }

    func testSkipLongBreakGoesToFocus() {
        var timer = PomodoroTimer()
        for _ in 0..<3 {
            _ = finishPhase(&timer) // focus
            _ = finishPhase(&timer) // short break
        }
        _ = finishPhase(&timer) // 4th focus
        XCTAssertEqual(timer.phase, .longBreak)
        timer.skip()
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.completedFocusSessions, 4)
    }

    func testSkippingFocusNeverTriggersLongBreak() {
        var timer = PomodoroTimer()
        for _ in 0..<3 {
            _ = finishPhase(&timer)
            _ = finishPhase(&timer)
        }
        XCTAssertEqual(timer.completedFocusSessions, 3)
        XCTAssertEqual(timer.phase, .focus)
        timer.skip()
        XCTAssertEqual(timer.phase, .shortBreak, "A skipped Focus is not the 4th completed one")
        XCTAssertEqual(timer.completedFocusSessions, 3)
        timer.skip()
        _ = finishPhase(&timer)
        XCTAssertEqual(timer.completedFocusSessions, 4)
        XCTAssertEqual(timer.phase, .longBreak)
    }

    func testSkipAfterLongBreakCycleStillShortBreak() {
        var timer = PomodoroTimer(configuration: .init(focus: 1, shortBreak: 1, longBreak: 1))
        for _ in 0..<4 {
            _ = finishPhase(&timer)
            if timer.phase == .shortBreak { _ = finishPhase(&timer) }
        }
        XCTAssertEqual(timer.phase, .longBreak)
        _ = finishPhase(&timer)
        XCTAssertEqual(timer.phase, .focus)
        timer.skip()
        XCTAssertEqual(timer.phase, .shortBreak, "Count is 4, but this Focus was skipped")
    }

    // MARK: Expiry and transitions

    func testFocusRunsOutIntoShortBreakRunning() {
        var timer = PomodoroTimer()
        timer.start()
        let completions = timer.tick(by: 1500)
        XCTAssertEqual(completions, [PhaseCompletion(finished: .focus, next: .shortBreak, completedFocusSessions: 1)])
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.remaining, 300)
        XCTAssertTrue(timer.isRunning, "The next phase starts right away")
        XCTAssertEqual(timer.completedFocusSessions, 1)
    }

    func testBreakRunsOutIntoFocusRunning() {
        var timer = PomodoroTimer()
        _ = finishPhase(&timer)
        let completions = finishPhase(&timer)
        XCTAssertEqual(completions.map(\.finished), [.shortBreak])
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.completedFocusSessions, 1, "Breaks do not change the count")
    }

    func testFullCycleWithLongBreakAfterFourthFocus() {
        var timer = PomodoroTimer()
        var sequence: [Phase] = [timer.phase]
        for _ in 0..<9 {
            _ = finishPhase(&timer)
            sequence.append(timer.phase)
        }
        XCTAssertEqual(sequence, [
            .focus, .shortBreak, .focus, .shortBreak, .focus, .shortBreak,
            .focus, .longBreak, .focus, .shortBreak,
        ])
        XCTAssertEqual(timer.completedFocusSessions, 5)
    }

    func testEighthFocusAlsoLeadsToLongBreak() {
        var timer = PomodoroTimer()
        var longBreaksAfter: [Int] = []
        for _ in 0..<16 {
            _ = finishPhase(&timer)
            if timer.phase == .longBreak { longBreaksAfter.append(timer.completedFocusSessions) }
        }
        XCTAssertEqual(longBreaksAfter, [4, 8])
    }

    func testFractionalTicksAccumulate() {
        var timer = PomodoroTimer(configuration: .uiTesting)
        timer.start()
        for _ in 0..<9 { timer.tick(by: 0.5) }
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.remaining, 0.5, accuracy: 1e-9)
        XCTAssertEqual(timer.formattedRemaining, "00:01")
        timer.tick(by: 0.5)
        XCTAssertEqual(timer.phase, .shortBreak)
    }

    func testLeftoverTimeCarriesIntoNextPhase() {
        var timer = PomodoroTimer(configuration: .uiTesting) // 5 / 3 / 4
        timer.start()
        let completions = timer.tick(by: 7)
        XCTAssertEqual(completions.map(\.finished), [.focus])
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.remaining, 1)
    }

    func testLargeTickCompletesSeveralPhases() {
        var timer = PomodoroTimer(configuration: .uiTesting) // 5 / 3 / 4
        timer.start()
        // focus 5 + short 3 + focus 5 = 13, then 1 s into the next short break
        let completions = timer.tick(by: 14)
        XCTAssertEqual(completions.map(\.finished), [.focus, .shortBreak, .focus])
        XCTAssertEqual(completions.last?.completedFocusSessions, 2)
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.remaining, 2)
        XCTAssertTrue(timer.isRunning)
    }

    func testUpcomingPhase() {
        var timer = PomodoroTimer(configuration: .uiTesting)
        XCTAssertEqual(timer.upcomingPhase, .shortBreak)
        for _ in 0..<3 {
            _ = finishPhase(&timer)
            _ = finishPhase(&timer)
        }
        XCTAssertEqual(timer.upcomingPhase, .longBreak)
        _ = finishPhase(&timer)
        XCTAssertEqual(timer.phase, .longBreak)
        XCTAssertEqual(timer.upcomingPhase, .focus)
    }

    func testCompletedInCurrentCycle() {
        var timer = PomodoroTimer(configuration: .uiTesting)
        var values: [Int] = []
        for _ in 0..<5 {
            _ = finishPhase(&timer)
            values.append(timer.completedInCurrentCycle)
            _ = finishPhase(&timer)
        }
        XCTAssertEqual(values, [1, 2, 3, 0, 1])
    }

    func testFractionRemaining() {
        var timer = PomodoroTimer()
        timer.start()
        timer.tick(by: 375)
        XCTAssertEqual(timer.fractionRemaining, 0.75, accuracy: 1e-9)
    }

    // MARK: Custom durations

    func testCustomDurations() {
        let config = PomodoroConfiguration(focus: 50 * 60, shortBreak: 10 * 60, longBreak: 30 * 60, focusSessionsBeforeLongBreak: 2)
        var timer = PomodoroTimer(configuration: config)
        XCTAssertEqual(timer.formattedRemaining, "50:00")
        _ = finishPhase(&timer)
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.formattedRemaining, "10:00")
        _ = finishPhase(&timer)
        _ = finishPhase(&timer)
        XCTAssertEqual(timer.phase, .longBreak, "Long break after every 2nd Focus with this config")
        XCTAssertEqual(timer.formattedRemaining, "30:00")
    }

    func testLongBreakEveryFocusWhenIntervalIsOne() {
        var timer = PomodoroTimer(configuration: .init(focus: 1, shortBreak: 1, longBreak: 2, focusSessionsBeforeLongBreak: 1))
        _ = finishPhase(&timer)
        XCTAssertEqual(timer.phase, .longBreak)
    }
}
