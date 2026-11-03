import SwiftUI
import PomodoroCore

@main
struct PomodoroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var model = TimerModel.shared

    var body: some Scene {
        MenuBarExtra {
            PanelView(model: model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        if model.showsIdleIcon {
            Image(systemName: "timer")
                .accessibilityLabel("Pomodoro")
        } else {
            Text(model.clock)
                .monospacedDigit()
                .accessibilityLabel("Pomodoro \(model.clock)")
        }
    }
}
