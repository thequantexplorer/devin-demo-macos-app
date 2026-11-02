import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var testingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = TimerModel.shared
        if LaunchOptions.isUITesting {
            showTestingWindow(model: model)
        } else {
            Notifier.shared.requestPermission()
        }
    }

    /// In -ui-testing mode the panel content also opens in a normal window,
    /// so XCUITest can reach it without clicking the menu bar.
    private func showTestingWindow(model: TimerModel) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 260),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pomodoro"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: PanelView(model: model))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        testingWindow = window
    }
}
