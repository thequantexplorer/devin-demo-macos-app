import SwiftUI

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = TimerModel.shared

    var body: some Scene {
        MenuBarExtra {
            PanelView(model: model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Time left while a phase is under way (running or paused mid-phase),
/// a timer icon at the full, untouched start of a phase.
struct MenuBarLabel: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        if model.timer.isUnderWay {
            Text(model.timer.formattedRemaining)
                .monospacedDigit()
                .accessibilityLabel("Pomodoro, \(model.timer.phase.title), \(model.timer.formattedRemaining) left")
        } else {
            Image(systemName: "timer")
                .accessibilityLabel("Pomodoro")
        }
    }
}
