import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var testingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if LaunchOptions.isUITesting {
            showTestingWindow()
        } else {
            NotificationService.shared.requestAuthorization()
        }
    }

    /// With `-ui-testing`, also host the panel in a normal window so XCUITest
    /// can reach it without going through the menu bar.
    private func showTestingWindow() {
        let hostingView = NSHostingView(rootView: PanelView(model: TimerModel.shared))
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.title = "Pomodoro"
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        testingWindow = window
    }
}

enum LaunchOptions {
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
}
