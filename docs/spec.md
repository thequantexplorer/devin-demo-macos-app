# Pomodoro menu bar app: spec

A small macOS menu bar app for the Pomodoro technique. It has no Dock icon and no main window. Everything happens in the panel that opens from the menu bar.

## Timer rules (PomodoroCore)

These rules live in `PomodoroCore` and are covered by `swift test`.

- There are three phases: **Focus** (25 min), **Short break** (5 min) and **Long break** (15 min).
- The timer starts paused, on a full Focus phase, with 0 completed focus sessions.
- **Start** runs the timer. Starting a running timer does nothing.
- **Pause** stops the timer and keeps the time left. Start again carries on from there.
- **Reset** stops the timer and puts the current phase back to its full length. It does not change the phase or the count.
- **Skip** ends the current phase now and moves to the next phase, paused and full length.
- When a phase runs out, the timer moves to the next phase and keeps running. The next phase starts at the exact moment the last one ended, even if the tick that notices comes late (for example after the Mac slept). If several phases ended before the tick, it moves through all of them.
- Each Focus phase that ends (by running out or by Skip) adds 1 to the completed count.
- After a Focus phase comes a Short break, except every 4th completed Focus, which is followed by a Long break. After any break comes Focus.
- Time left never goes below 0.
- Times show as `MM:SS`, with partial seconds rounded up (`1499.2` s shows as `25:00`).

## The app (Pomodoro target)

The menu bar item:

- Shows a timer icon when the timer is paused on a full-length phase (at launch, and after Reset or Skip).
- Otherwise shows the time left, for example `24:59`.

The panel (opened by clicking the menu bar item) shows, top to bottom:

| What | Accessibility identifier | Example |
| --- | --- | --- |
| Phase name | `phaseLabel` | `Focus` |
| Time left, updated every second | `timeLabel` | `25:00` |
| Start / Pause button (title changes with state) | `startPauseButton` | `Start` |
| Reset button | `resetButton` | `Reset` |
| Skip button | `skipButton` | `Skip` |
| Completed focus sessions | `completedLabel` | `Completed: 0` |
| Quit button | `quitButton` | `Quit` |

When a phase ends, the app posts a local notification: "Focus done. Time for a short break.", "Focus done. Time for a long break." or "Break done. Time to focus." It asks for notification permission the first time it starts. If permission is denied, the timer still works.

## UI testing mode

When the app is launched with the `-ui-testing` argument:

- The durations are short so tests run fast: Focus 5 s, Short break 3 s, Long break 4 s.
- The app does not ask for notification permission.
- The panel content also opens in a normal window titled `Pomodoro`, so XCUITest can find it without clicking the menu bar.

Tips:

- With a macOS 13 target you can't add a scene with a plain `if` in `App.body` (it does not compile). Open the window from an app delegate instead (`NSWindow` with an `NSHostingView`).
- XCUITest can also click the real menu bar item: `app.statusItems.firstMatch.click()` opens the panel.
- Read button text with `.label` (`.title` is empty for SwiftUI buttons) and text with `.value as? String ?? .label`, like the starter UI test.
- Find the Start / Pause button by its identifier, not its title, because the title changes.

## Commands

```sh
# Timer logic only (works on Linux too)
swift test --package-path PomodoroCore

# App + UI tests on macOS
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' test
```

If the UI tests fail with "Timed out while enabling automation mode", run `sudo automationmodetool enable-automationmode-without-authentication`, run the tests again, and type the Mac's password if a "XCTest is trying to Enable UI Automation" dialog appears.
