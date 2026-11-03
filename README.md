# Pomodoro

A small macOS menu bar app for the Pomodoro technique: 25 minutes of focus, then a short break, with a long break after every 4th focus session. It lives in the menu bar and has no Dock icon.

Click the timer in the menu bar to open the panel: Start / Pause, Reset, Skip, and a count of completed focus sessions. The menu bar shows the time left while a phase is in progress.

```
Pomodoro/            SwiftUI app target (MenuBarExtra), macOS 13+
PomodoroCore/        Swift package with the timer logic and its unit tests
PomodoroUITests/     XCUITest UI tests
Pomodoro.xcodeproj   Xcode project (generated from project.yml with XcodeGen)
```

## Commands

```sh
# Timer logic only. Works on macOS and Linux; CI runs this on every push.
swift test --package-path PomodoroCore

# App, unit tests and UI tests. Needs macOS with Xcode 16 or later.
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' test
```

On a new Mac the first UI test run can fail with "Timed out while enabling automation mode". Run `sudo automationmodetool enable-automationmode-without-authentication`, run the tests again, and type the Mac's password if a "XCTest is trying to Enable UI Automation" dialog appears.

Build, test and recording notes are in [.agents/skills/build-and-test/SKILL.md](.agents/skills/build-and-test/SKILL.md). The Xcode project uses synchronized folders, so new `.swift` files in `Pomodoro/` or `PomodoroUITests/` are picked up without editing the project. The app is signed to run locally, so no Apple developer account is needed.

