import XCTest

/// Launched with `-ui-testing`: Focus 5 s, Short break 3 s, Long break 4 s,
/// and the panel is also shown in a window titled "Pomodoro".
final class PomodoroUITests: XCTestCase {
    private var app: XCUIApplication!
    private var panel: XCUIElement!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        panel = app.windows["Pomodoro"]
        XCTAssertTrue(panel.waitForExistence(timeout: 10), "The -ui-testing window should open")
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: Helpers

    private var phaseLabel: XCUIElement { panel.staticTexts["phaseLabel"] }
    private var timeLabel: XCUIElement { panel.staticTexts["timeLabel"] }
    private var completedLabel: XCUIElement { panel.staticTexts["completedLabel"] }
    private var startPauseButton: XCUIElement { panel.buttons["startPauseButton"] }
    private var resetButton: XCUIElement { panel.buttons["resetButton"] }
    private var skipButton: XCUIElement { panel.buttons["skipButton"] }

    private func text(_ element: XCUIElement) -> String {
        element.value as? String ?? element.label
    }

    private func waitFor(_ description: String, timeout: TimeInterval = 5, _ condition: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in condition() }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        expectation.expectationDescription = description
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed, description)
    }

    private func assertPhase(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(text(phaseLabel).lowercased(), title.lowercased(), file: file, line: line)
    }

    // MARK: Tests

    func testInitialState() {
        for element in [phaseLabel, timeLabel, completedLabel, startPauseButton, resetButton, skipButton, panel.buttons["quitButton"]] {
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) should exist")
        }
        assertPhase("Focus")
        XCTAssertEqual(text(timeLabel), "00:05")
        XCTAssertEqual(startPauseButton.label, "Start")
        XCTAssertEqual(text(completedLabel), "Completed: 0")
        XCTAssertFalse(resetButton.isEnabled, "Nothing to reset at the start of a phase")
    }

    func testStartRunsTheTimer() {
        startPauseButton.click()
        XCTAssertEqual(startPauseButton.label, "Pause")
        waitFor("time should count down") { self.text(self.timeLabel) != "00:05" }
        assertPhase("Focus")
    }

    func testPauseStopsTheTimer() {
        startPauseButton.click()
        waitFor("time should count down") { self.text(self.timeLabel) == "00:04" }
        startPauseButton.click()
        XCTAssertEqual(startPauseButton.label, "Resume")
        let paused = text(timeLabel)
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual(text(timeLabel), paused, "Paused time must not move")

        startPauseButton.click()
        XCTAssertEqual(startPauseButton.label, "Pause")
        waitFor("time should count down again after resuming") { self.text(self.timeLabel) != paused }
    }

    func testResetGoesBackToStartOfPhase() {
        startPauseButton.click()
        waitFor("time should count down") { self.text(self.timeLabel) == "00:04" }
        XCTAssertTrue(resetButton.isEnabled)
        resetButton.click()
        XCTAssertEqual(text(timeLabel), "00:05")
        XCTAssertEqual(startPauseButton.label, "Start")
        assertPhase("Focus")
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(text(timeLabel), "00:05", "Reset pauses the timer")
    }

    func testSkipMovesToNextPhasePaused() {
        skipButton.click()
        assertPhase("Short break")
        XCTAssertEqual(text(timeLabel), "00:03")
        XCTAssertEqual(startPauseButton.label, "Start")
        XCTAssertEqual(text(completedLabel), "Completed: 0", "Skip does not count a Focus as completed")

        skipButton.click()
        assertPhase("Focus")
        XCTAssertEqual(text(timeLabel), "00:05")
        XCTAssertEqual(startPauseButton.label, "Start")
    }

    func testFocusRunsOutIntoShortBreak() {
        startPauseButton.click()
        waitFor("Focus should run out into a Short break", timeout: 10) {
            self.text(self.phaseLabel).lowercased() == "short break"
        }
        XCTAssertEqual(text(completedLabel), "Completed: 1")
        XCTAssertEqual(startPauseButton.label, "Pause", "The next phase starts right away")
        waitFor("the Short break should be counting down") {
            ["00:02", "00:01"].contains(self.text(self.timeLabel))
        }
    }

    func testMenuBarItemOpensPanel() {
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5))
        statusItem.click()
        let panelButtons = app.buttons.matching(identifier: "startPauseButton")
        waitFor("the menu bar panel should open") { panelButtons.count >= 2 }
    }
}
