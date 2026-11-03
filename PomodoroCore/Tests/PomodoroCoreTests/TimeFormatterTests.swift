import XCTest
@testable import PomodoroCore

final class TimeFormatterTests: XCTestCase {
    func testWholeMinutes() {
        XCTAssertEqual(TimeFormatter.minutesSeconds(25 * 60), "25:00")
        XCTAssertEqual(TimeFormatter.minutesSeconds(5 * 60), "05:00")
        XCTAssertEqual(TimeFormatter.minutesSeconds(15 * 60), "15:00")
    }

    func testMinutesAndSeconds() {
        XCTAssertEqual(TimeFormatter.minutesSeconds(1499), "24:59")
        XCTAssertEqual(TimeFormatter.minutesSeconds(61), "01:01")
        XCTAssertEqual(TimeFormatter.minutesSeconds(59), "00:59")
        XCTAssertEqual(TimeFormatter.minutesSeconds(5), "00:05")
    }

    func testZeroAndNegative() {
        XCTAssertEqual(TimeFormatter.minutesSeconds(0), "00:00")
        XCTAssertEqual(TimeFormatter.minutesSeconds(-3), "00:00")
        XCTAssertEqual(TimeFormatter.minutesSeconds(.nan), "00:00")
        XCTAssertEqual(TimeFormatter.minutesSeconds(.infinity), "00:00")
    }

    func testFractionsRoundUp() {
        XCTAssertEqual(TimeFormatter.minutesSeconds(0.2), "00:01")
        XCTAssertEqual(TimeFormatter.minutesSeconds(59.01), "01:00")
        XCTAssertEqual(TimeFormatter.minutesSeconds(1499.5), "25:00")
    }

    func testMoreThanAnHour() {
        XCTAssertEqual(TimeFormatter.minutesSeconds(90 * 60), "90:00")
        XCTAssertEqual(TimeFormatter.minutesSeconds(100 * 60 + 5), "100:05")
    }
}
