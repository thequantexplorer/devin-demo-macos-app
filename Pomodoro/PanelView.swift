import SwiftUI
import AppKit

/// The panel shown from the menu bar (and, in -ui-testing mode, in a window).
struct PanelView: View {
    @ObservedObject var model: TimerModel

    var body: some View {
        VStack(spacing: 12) {
            Text(model.phaseTitle)
                .font(.headline)
                .accessibilityIdentifier("phaseLabel")

            Text(model.timeText)
                .font(.system(size: 40, weight: .medium, design: .rounded).monospacedDigit())
                .accessibilityIdentifier("timeLabel")

            Button(model.isRunning ? "Pause" : "Start") {
                model.startPause()
            }
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("startPauseButton")

            HStack {
                Button("Reset") { model.reset() }
                    .accessibilityIdentifier("resetButton")
                Button("Skip") { model.skip() }
                    .accessibilityIdentifier("skipButton")
            }

            Text("Completed: \(model.completedFocusSessions)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("completedLabel")

            Divider()

            Button("Quit") { NSApp.terminate(nil) }
                .accessibilityIdentifier("quitButton")
        }
        .padding()
        .frame(width: 220)
    }
}
