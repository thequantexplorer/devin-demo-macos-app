import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let notifier = Notifier()
    private var testingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = TimerModel.shared
        if LaunchOptions.isUITesting {
            showTestingWindow(model: model)
        } else {
            notifier.requestPermission()
            model.onPhaseFinished = { [notifier] finished, next in
                notifier.phaseFinished(finished, next: next)
            }
        }
    }

    /// In -ui-testing mode the panel also opens in a normal window so XCUITest can reach it.
    private func showTestingWindow(model: TimerModel) {
        let hosting = NSHostingView(rootView: PanelView(model: model).background(VisualEffectBackground()))
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pomodoro"
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        testingWindow = window
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
