# Devin demo: build a macOS menu bar app and test it

**What it shows:** Devin starts a macOS child session with Xcode, builds a Pomodoro timer that lives in the macOS menu bar, writes XCUITest UI tests, runs them, and sends you a recording of the app working.

**Needs:** GitHub

## Set it up

1. Click **Use this template → Create a new repository**, choose your GitHub account as the owner, and keep the name `devin-demo-macos-app`. The prompt below assumes that name. Use the template rather than a fork: pull requests on a fork go to the original repo by default.
2. In Devin, open [**Settings → Connections → GitHub**](https://app.devin.ai/settings/connections/github) and make sure Devin can access the new repository.

## Prompt

Start a new Devin session at [app.devin.ai](https://app.devin.ai) and paste this. Replace `<you>` with your GitHub user.

```text
Build the Pomodoro macOS menu bar app in https://github.com/<you>/devin-demo-macos-app. The spec is docs/spec.md. This needs Xcode, so start a macOS child session and do the work there.

Follow the repo's design skill. The result should look like a finished, polished product.

1. Implement the timer logic in PomodoroCore until `swift test --package-path PomodoroCore` passes. Do not change the existing tests.
2. Build the menu bar panel and the -ui-testing mode exactly as the spec says, with the listed accessibility identifiers.
3. Write XCUITest UI tests in PomodoroUITests that check Start, Pause, Reset and Skip, and that a short focus phase runs out and moves to a short break. Run everything with `xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -destination 'platform=macOS' test` until it passes.
4. Launch the app normally (allow or dismiss the notification prompt if one appears), then record the screen while you click the timer in the menu bar, start it, pause it, skip to a break and reset. Attach the recording to the session.

Open a PR with the code and the tests. In the description, paste the test summary from xcodebuild and list what the recording shows.
```

## What to watch

- Devin starts a macOS child session, because the app needs Xcode.
- It runs the failing tests first, then makes them pass.
- It clicks the real menu bar item while it records.

## Done when

- `xcodebuild ... test` passes, with the unit tests and your new UI tests.
- The session has a recording of the panel opening from the menu bar and the timer counting down.
- There is a PR with the code, the UI tests and the test summary.
