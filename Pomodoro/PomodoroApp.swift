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
            if model.isPausedAtFullLength {
                Image(systemName: "timer")
            } else {
                Text(model.timeText)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
