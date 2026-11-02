import Foundation
import PomodoroCore

enum LaunchOptions {
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    static var settings: PomodoroSettings {
        isUITesting
            ? PomodoroSettings(focus: 5, shortBreak: 3, longBreak: 4)
            : .standard
    }
}
