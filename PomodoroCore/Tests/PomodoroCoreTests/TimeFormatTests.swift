import XCTest
@testable import PomodoroCore

final class TimeFormatTests: XCTestCase {
    func testWholeMinutes() {
        XCTAssertEqual(TimeFormat.clock(25 * 60), "25:00")
        XCTAssertEqual(TimeFormat.clock(5 * 60), "05:00")
    }

    func testSecondsArePadded() {
        XCTAssertEqual(TimeFormat.clock(65), "01:05")
        XCTAssertEqual(TimeFormat.clock(9), "00:09")
    }

    func testPartialSecondsRoundUp() {
        XCTAssertEqual(TimeFormat.clock(1499.2), "25:00")
        XCTAssertEqual(TimeFormat.clock(0.4), "00:01")
    }

    func testZeroAndNegative() {
        XCTAssertEqual(TimeFormat.clock(0), "00:00")
        XCTAssertEqual(TimeFormat.clock(-3), "00:00")
    }

    func testOverAnHour() {
        XCTAssertEqual(TimeFormat.clock(61 * 60), "61:00")
    }
}
