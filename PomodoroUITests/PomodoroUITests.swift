import XCTest

/// UI tests for the menu bar panel. See docs/spec.md for the
/// accessibility identifiers and the -ui-testing launch argument.
/// In -ui-testing mode the durations are Focus 5 s, Short break 3 s, Long break 4 s.
final class PomodoroUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Elements (in the -ui-testing window)

    private var window: XCUIElement { app.windows["Pomodoro"] }
    private var phaseLabel: XCUIElement { window.staticTexts["phaseLabel"] }
    private var timeLabel: XCUIElement { window.staticTexts["timeLabel"] }
    private var completedLabel: XCUIElement { window.staticTexts["completedLabel"] }
    private var startPauseButton: XCUIElement { window.buttons["startPauseButton"] }
    private var resetButton: XCUIElement { window.buttons["resetButton"] }
    private var skipButton: XCUIElement { window.buttons["skipButton"] }

    private func text(_ element: XCUIElement) -> String {
        element.value as? String ?? element.label
    }

    /// Polls `condition` until it is true or `timeout` passes.
    private func waitUntil(
        timeout: TimeInterval,
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertTrue(condition(), message, file: file, line: line)
    }

    private func assertFullFocusPhase(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(text(phaseLabel), "Focus", file: file, line: line)
        XCTAssertEqual(text(timeLabel), "00:05", file: file, line: line)
        XCTAssertEqual(startPauseButton.label, "Start", file: file, line: line)
        XCTAssertEqual(text(completedLabel), "Completed: 0", file: file, line: line)
    }

    // MARK: - Tests

    func testPanelShowsAFullFocusPhase() {
        let time = app.staticTexts["timeLabel"]
        XCTAssertTrue(time.waitForExistence(timeout: 10), "The panel should show the time left.")
        XCTAssertEqual(time.value as? String ?? time.label, "00:05")
    }

    func testPanelShowsAllControls() {
        XCTAssertTrue(window.waitForExistence(timeout: 10), "The -ui-testing window should open.")
        assertFullFocusPhase()
        XCTAssertEqual(resetButton.label, "Reset")
        XCTAssertEqual(skipButton.label, "Skip")
        XCTAssertEqual(window.buttons["quitButton"].label, "Quit")
    }

    func testStartCountsDown() {
        XCTAssertTrue(startPauseButton.waitForExistence(timeout: 10))
        startPauseButton.click()

        XCTAssertEqual(startPauseButton.label, "Pause")
        waitUntil(timeout: 3, "The time left should count down after Start.") {
            text(timeLabel) == "00:04"
        }
        XCTAssertEqual(text(phaseLabel), "Focus")
    }

    func testPauseFreezesTheTimeAndStartResumes() {
        XCTAssertTrue(startPauseButton.waitForExistence(timeout: 10))
        startPauseButton.click()
        waitUntil(timeout: 3, "The timer should be running.") { text(timeLabel) == "00:04" }

        startPauseButton.click()
        XCTAssertEqual(startPauseButton.label, "Start")
        let frozen = text(timeLabel)
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual(text(timeLabel), frozen, "The time left should not change while paused.")
        XCTAssertEqual(text(phaseLabel), "Focus")

        startPauseButton.click()
        XCTAssertEqual(startPauseButton.label, "Pause")
        waitUntil(timeout: 3, "The timer should carry on after Start.") { text(timeLabel) != frozen }
    }

    func testResetStopsAndRefillsTheCurrentPhase() {
        XCTAssertTrue(startPauseButton.waitForExistence(timeout: 10))
        startPauseButton.click()
        waitUntil(timeout: 3, "The timer should be running.") { text(timeLabel) == "00:04" }

        resetButton.click()
        assertFullFocusPhase()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(text(timeLabel), "00:05", "Reset should stop the timer.")
    }

    func testResetKeepsThePhaseAndCount() {
        XCTAssertTrue(skipButton.waitForExistence(timeout: 10))
        skipButton.click()
        startPauseButton.click()
        waitUntil(timeout: 3, "The break should be running.") { text(timeLabel) == "00:02" }

        resetButton.click()
        XCTAssertEqual(text(phaseLabel), "Short break")
        XCTAssertEqual(text(timeLabel), "00:03")
        XCTAssertEqual(text(completedLabel), "Completed: 1")
        XCTAssertEqual(startPauseButton.label, "Start")
    }

    func testSkipMovesToAPausedFullShortBreak() {
        XCTAssertTrue(skipButton.waitForExistence(timeout: 10))
        startPauseButton.click()
        skipButton.click()

        XCTAssertEqual(text(phaseLabel), "Short break")
        XCTAssertEqual(text(timeLabel), "00:03")
        XCTAssertEqual(text(completedLabel), "Completed: 1")
        XCTAssertEqual(startPauseButton.label, "Start")

        skipButton.click()
        XCTAssertEqual(text(phaseLabel), "Focus")
        XCTAssertEqual(text(timeLabel), "00:05")
        XCTAssertEqual(text(completedLabel), "Completed: 1", "Skipping a break does not count a focus session.")
    }

    func testEveryFourthFocusIsFollowedByALongBreak() {
        XCTAssertTrue(skipButton.waitForExistence(timeout: 10))
        for _ in 0..<3 {
            skipButton.click()
            XCTAssertEqual(text(phaseLabel), "Short break")
            skipButton.click()
            XCTAssertEqual(text(phaseLabel), "Focus")
        }
        skipButton.click()
        XCTAssertEqual(text(phaseLabel), "Long break")
        XCTAssertEqual(text(timeLabel), "00:04")
        XCTAssertEqual(text(completedLabel), "Completed: 4")
    }

    func testShortFocusRunsOutAndMovesToAShortBreak() {
        XCTAssertTrue(startPauseButton.waitForExistence(timeout: 10))
        startPauseButton.click()

        waitUntil(timeout: 10, "Focus (5 s) should run out and move to a short break.") {
            text(phaseLabel) == "Short break"
        }
        XCTAssertEqual(text(completedLabel), "Completed: 1")
        XCTAssertEqual(startPauseButton.label, "Pause", "The timer keeps running into the break.")
        let breakTime = text(timeLabel)
        XCTAssertTrue(["00:03", "00:02"].contains(breakTime), "Unexpected break time \(breakTime)")
    }

    func testMenuBarItemOpensThePanel() {
        XCTAssertTrue(window.waitForExistence(timeout: 10))
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10), "The app should have a menu bar item.")
        statusItem.click()

        let panelTime = app.staticTexts.matching(identifier: "timeLabel")
        waitUntil(timeout: 5, "Clicking the menu bar item should open the panel.") {
            panelTime.count >= 2
        }
        XCTAssertTrue(app.buttons.matching(identifier: "quitButton").count >= 2)
    }
}
