import XCTest

/// UI tests for the menu bar panel. See docs/spec.md for the
/// accessibility identifiers and the -ui-testing launch argument.
final class PomodoroUITests: XCTestCase {
    func testPanelShowsAFullFocusPhase() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let time = app.staticTexts["timeLabel"]
        XCTAssertTrue(time.waitForExistence(timeout: 10), "The panel should show the time left.")
        XCTAssertEqual(time.value as? String ?? time.label, "00:05")
    }
}
