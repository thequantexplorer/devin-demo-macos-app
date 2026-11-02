import XCTest
@testable import PomodoroCore

/// A manually advanced clock for deterministic tests.
private final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var current = Date(timeIntervalSinceReferenceDate: 0)

    var now: Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    func advance(_ seconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        current += seconds
    }
}

final class PomodoroSessionTests: XCTestCase {
    private var clock: TestClock!
    private var session: PomodoroSession!

    override func setUp() {
        super.setUp()
        clock = TestClock()
        let clock = clock!
        session = PomodoroSession(configuration: .uiTesting, now: { clock.now })
    }

    func testElapsedTimeComesFromClock() {
        session.start()
        clock.advance(2.5)
        session.update()
        XCTAssertEqual(session.timer.remaining, 2.5, accuracy: 1e-9)
        XCTAssertEqual(session.timer.formattedRemaining, "00:03")
    }

    func testUpdateWithoutStartDoesNothing() {
        clock.advance(10)
        XCTAssertEqual(session.update(), [])
        XCTAssertEqual(session.timer.remaining, 5)
    }

    func testPausedTimeIsNotCounted() {
        session.start()
        clock.advance(1)
        session.pause()
        XCTAssertEqual(session.timer.remaining, 4, "Pause applies time elapsed so far")
        clock.advance(100)
        session.update()
        XCTAssertEqual(session.timer.remaining, 4)
        session.start()
        clock.advance(1)
        session.update()
        XCTAssertEqual(session.timer.remaining, 3)
    }

    func testToggle() {
        session.toggle()
        XCTAssertTrue(session.timer.isRunning)
        clock.advance(1)
        session.toggle()
        XCTAssertFalse(session.timer.isRunning)
        XCTAssertEqual(session.timer.remaining, 4)
    }

    func testExpiryReportsCompletionAndKeepsRunning() {
        session.start()
        clock.advance(5)
        let completions = session.update()
        XCTAssertEqual(completions, [PhaseCompletion(finished: .focus, next: .shortBreak, completedFocusSessions: 1)])
        XCTAssertEqual(session.timer.phase, .shortBreak)
        XCTAssertTrue(session.timer.isRunning)
        clock.advance(1)
        session.update()
        XCTAssertEqual(session.timer.remaining, 2)
    }

    func testResetAndSkipStopTheClock() {
        session.start()
        clock.advance(2)
        session.reset()
        clock.advance(2)
        session.update()
        XCTAssertEqual(session.timer.remaining, 5)
        XCTAssertTrue(session.timer.isAtPhaseStart)

        session.start()
        clock.advance(1)
        session.skip()
        clock.advance(2)
        session.update()
        XCTAssertEqual(session.timer.phase, .shortBreak)
        XCTAssertEqual(session.timer.remaining, 3)
        XCTAssertFalse(session.timer.isRunning)
        XCTAssertEqual(session.timer.completedFocusSessions, 0)
    }

    func testIrregularUpdateIntervalsDoNotDrift() {
        session.start()
        for step in [0.3, 1.1, 0.9, 0.7] {
            clock.advance(step)
            session.update()
        }
        XCTAssertEqual(session.timer.remaining, 2.0, accuracy: 1e-9)
    }
}
