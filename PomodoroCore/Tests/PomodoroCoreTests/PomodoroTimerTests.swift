import XCTest
@testable import PomodoroCore

final class PomodoroTimerTests: XCTestCase {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)

    func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

    func testStartsPausedOnAFullFocusPhase() {
        let timer = PomodoroTimer()
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.completedFocusSessions, 0)
        XCTAssertEqual(timer.remaining(at: t0), 25 * 60)
    }

    func testCountsDownWhileRunning() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.remaining(at: at(60)), 24 * 60)
    }

    func testPauseFreezesTheTimeLeft() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        timer.pause(at: at(100))
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remaining(at: at(500)), 1400)
    }

    func testResumeContinuesFromWhereItPaused() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        timer.pause(at: at(100))
        timer.start(at: at(1000))
        XCTAssertEqual(timer.remaining(at: at(1010)), 1390)
    }

    func testStartTwiceDoesNotRestart() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        timer.start(at: at(30))
        XCTAssertEqual(timer.remaining(at: at(60)), 1440)
    }

    func testResetStopsAndRefillsTheCurrentPhase() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        timer.reset()
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.remaining(at: at(300)), 25 * 60)
    }

    func testFinishedFocusMovesToShortBreakAndKeepsRunning() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        XCTAssertFalse(timer.tick(at: at(1499)))
        XCTAssertTrue(timer.tick(at: at(1500)))
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.completedFocusSessions, 1)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.remaining(at: at(1500)), 5 * 60)
        XCTAssertEqual(timer.remaining(at: at(1560)), 4 * 60)
    }

    func testFinishedBreakMovesBackToFocus() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        timer.tick(at: at(1500))
        XCTAssertTrue(timer.tick(at: at(1800)))
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.completedFocusSessions, 1)
    }

    func testEveryFourthFocusIsFollowedByALongBreak() {
        let settings = PomodoroSettings(focus: 10, shortBreak: 2, longBreak: 5, focusSessionsBeforeLongBreak: 4)
        var timer = PomodoroTimer(settings: settings)
        var phases: [Phase] = []
        for _ in 0..<8 {
            timer.skip()
            phases.append(timer.phase)
        }
        XCTAssertEqual(phases, [.shortBreak, .focus, .shortBreak, .focus, .shortBreak, .focus, .longBreak, .focus])
        XCTAssertEqual(timer.completedFocusSessions, 4)
    }

    func testSkipPausesAndFillsTheNextPhase() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        timer.skip()
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remaining(at: at(9999)), 5 * 60)
    }

    func testSkippingABreakDoesNotCountAFocusSession() {
        var timer = PomodoroTimer()
        timer.skip()
        timer.skip()
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.completedFocusSessions, 1)
    }

    func testTickWhilePausedDoesNothing() {
        var timer = PomodoroTimer()
        XCTAssertFalse(timer.tick(at: at(5000)))
        XCTAssertEqual(timer.phase, .focus)
        XCTAssertEqual(timer.remaining(at: at(5000)), 25 * 60)
    }

    func testALateTickDoesNotLoseTime() {
        // The Mac slept through the end of focus: the break started at 1500 s, not at the late tick.
        var timer = PomodoroTimer()
        timer.start(at: t0)
        XCTAssertTrue(timer.tick(at: at(1600)))
        XCTAssertEqual(timer.phase, .shortBreak)
        XCTAssertEqual(timer.remaining(at: at(1600)), 200)
    }

    func testRemainingNeverGoesBelowZero() {
        var timer = PomodoroTimer()
        timer.start(at: t0)
        XCTAssertEqual(timer.remaining(at: at(99999)), 0)
    }
}
