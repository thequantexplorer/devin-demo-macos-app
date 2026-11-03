---
name: build-and-test
description: Create, build, test and record the Pomodoro macOS menu bar app. Use for any task that builds, runs or tests this app. Needs macOS with Xcode.
---

This app needs macOS with Xcode. It does not build on Linux.

## Project layout

- `PomodoroCore/`: a Swift package with the timer logic and its XCTest unit tests. No UI code. `swift test --package-path PomodoroCore` runs them (this also works on Linux).
- `Pomodoro/`: the SwiftUI app. Menu bar only: no Dock icon and no main window (`LSUIElement`), macOS 13 or later.
- `PomodoroUITests/`: XCUITest UI tests.
- Generate `Pomodoro.xcodeproj` with XcodeGen and commit both `project.yml` and the project:

```sh
brew install xcodegen
xcodegen
```

```yaml
name: Pomodoro
options:
  bundleIdPrefix: dev.devinworkshop
  deploymentTarget:
    macOS: "13.0"
  createIntermediateGroups: true
packages:
  PomodoroCore:
    path: PomodoroCore
settings:
  base:
    SWIFT_VERSION: "5.0"
    CODE_SIGN_STYLE: Manual
    CODE_SIGN_IDENTITY: "-"
    DEVELOPMENT_TEAM: ""
    ENABLE_HARDENED_RUNTIME: NO
targets:
  Pomodoro:
    type: application
    platform: macOS
    sources: [Pomodoro]
    dependencies:
      - package: PomodoroCore
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: dev.devinworkshop.Pomodoro
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_CFBundleDisplayName: Pomodoro
        INFOPLIST_KEY_LSUIElement: YES
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
  PomodoroUITests:
    type: bundle.ui-testing
    platform: macOS
    sources: [PomodoroUITests]
    dependencies:
      - target: Pomodoro
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: dev.devinworkshop.PomodoroUITests
        GENERATE_INFOPLIST_FILE: YES
        TEST_TARGET_NAME: Pomodoro
schemes:
  Pomodoro:
    build:
      targets:
        Pomodoro: all
        PomodoroUITests: [test]
    test:
      targets:
        - PomodoroUITests
        - package: PomodoroCore/PomodoroCoreTests
```

Add a `.gitignore` with `.build/`, `build/`, `DerivedData/` and `xcuserdata/`.

## Make the panel testable

- Give every control in the panel an accessibility identifier: `phaseLabel`, `timeLabel`, `startPauseButton`, `resetButton`, `skipButton`, `completedLabel`, `quitButton`.
- When launched with the `-ui-testing` argument, use short durations (Focus 5 s, Short break 3 s, Long break 4 s), skip the notification permission prompt, and also open the panel content in a normal window titled `Pomodoro`, so XCUITest can find it without the menu bar.
- With a macOS 13 target you can't add a scene with a plain `if` in `App.body` (it does not compile). Open that window from an app delegate instead (`NSWindow` with an `NSHostingView`).
- XCUITest can click the real menu bar item: `app.statusItems.firstMatch.click()` opens the panel.
- Read SwiftUI button text with `.label` (`.title` is empty) and text with `.value as? String ?? .label`. Find the Start / Pause button by its identifier, because its title changes.

## Test

```sh
swift test --package-path PomodoroCore
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' test
```

If the UI tests fail with "Timed out while enabling automation mode", run `sudo automationmodetool enable-automationmode-without-authentication`, run the tests again, and type the Mac's password if a "XCTest is trying to Enable UI Automation" dialog appears.

## Record

Launch the built app normally (allow or dismiss the notification prompt if one appears). Record the screen while you click the timer in the menu bar to open the panel and use the buttons.
