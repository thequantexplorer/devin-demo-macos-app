import SwiftUI
import PomodoroCore

@main
struct PomodoroApp: App {
    var body: some Scene {
        MenuBarExtra("Pomodoro", systemImage: "timer") {
            // TODO: build the panel described in docs/spec.md.
            Text("Not built yet. See docs/spec.md.")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
