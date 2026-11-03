import XCTest

/// UI tests for the menu bar panel. See .agents/skills/build-and-test/SKILL.md
/// for the accessibility identifiers and the -ui-testing launch argument.
final class PomodoroUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testPanelShowsAFullFocusPhase() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let time = app.staticTexts["timeLabel"]
        XCTAssertTrue(time.waitForExistence(timeout: 10), "The panel should show the time left.")
        XCTAssertEqual(time.value as? String ?? time.label, "00:05")
    }

    func testStartRunsTheTimer() {
        let panel = launchPanel()
        XCTAssertEqual(panel.startPause.label, "Start")

        panel.startPause.click()

        XCTAssertTrue(wait(until: { panel.startPause.label == "Pause" }), "Start should turn into Pause.")
        XCTAssertTrue(wait(until: { panel.time == "00:04" }), "The time should count down after Start.")
        XCTAssertEqual(panel.phase, "Focus")
    }

    func testPauseKeepsTheTimeLeft() {
        let panel = launchPanel()
        panel.startPause.click()
        XCTAssertTrue(wait(until: { panel.time == "00:04" }))

        panel.startPause.click()

        XCTAssertTrue(wait(until: { panel.startPause.label == "Start" }), "Pause should turn back into Start.")
        let pausedAt = panel.time
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual(panel.time, pausedAt, "The time should not change while paused.")
        XCTAssertEqual(panel.phase, "Focus")
    }

    func testResetRefillsTheCurrentPhase() {
        let panel = launchPanel()
        panel.startPause.click()
        XCTAssertTrue(wait(until: { panel.time == "00:04" }))

        panel.reset.click()

        XCTAssertTrue(wait(until: { panel.time == "00:05" }), "Reset should put Focus back to full length.")
        XCTAssertEqual(panel.startPause.label, "Start")
        XCTAssertEqual(panel.phase, "Focus")
        XCTAssertEqual(panel.completed, "Completed: 0")
    }

    func testSkipMovesToAPausedShortBreak() {
        let panel = launchPanel()
        panel.startPause.click()

        panel.skip.click()

        XCTAssertTrue(wait(until: { panel.phase == "Short break" }), "Skip should end Focus.")
        XCTAssertEqual(panel.time, "00:03")
        XCTAssertEqual(panel.startPause.label, "Start")
        XCTAssertEqual(panel.completed, "Completed: 1")

        panel.skip.click()

        XCTAssertTrue(wait(until: { panel.phase == "Focus" }), "Skip on a break should go back to Focus.")
        XCTAssertEqual(panel.time, "00:05")
        XCTAssertEqual(panel.completed, "Completed: 1")
    }

    func testAFinishedFocusPhaseMovesToAShortBreak() {
        let panel = launchPanel()
        XCTAssertEqual(panel.completed, "Completed: 0")

        panel.startPause.click()

        XCTAssertTrue(wait(timeout: 10, until: { panel.phase == "Short break" }), "Focus should run out into a short break.")
        XCTAssertEqual(panel.completed, "Completed: 1")
        XCTAssertEqual(panel.startPause.label, "Pause", "The break should start running on its own.")
        XCTAssertTrue(["00:03", "00:02"].contains(panel.time), "Got \(panel.time)")
        XCTAssertTrue(wait(until: { panel.time == "00:01" }), "The short break should count down.")
    }

    func testQuitButtonIsInThePanel() {
        let panel = launchPanel()
        XCTAssertTrue(panel.quit.exists)
        XCTAssertEqual(panel.quit.label, "Quit")
    }

    // MARK: - Helpers

    private struct Panel {
        let root: XCUIElement

        var startPause: XCUIElement { root.buttons["startPauseButton"] }
        var reset: XCUIElement { root.buttons["resetButton"] }
        var skip: XCUIElement { root.buttons["skipButton"] }
        var quit: XCUIElement { root.buttons["quitButton"] }

        var phase: String { text("phaseLabel") }
        var time: String { text("timeLabel") }
        var completed: String { text("completedLabel") }

        private func text(_ identifier: String) -> String {
            let element = root.staticTexts[identifier]
            return element.value as? String ?? element.label
        }
    }

    private func launchPanel() -> Panel {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        let window = app.windows["Pomodoro"]
        XCTAssertTrue(window.waitForExistence(timeout: 10), "-ui-testing should open the panel in a window.")
        let panel = Panel(root: window)
        XCTAssertTrue(panel.startPause.waitForExistence(timeout: 5))
        XCTAssertEqual(panel.time, "00:05")
        return panel
    }

    private func wait(timeout: TimeInterval = 5, until condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return condition()
    }
}
