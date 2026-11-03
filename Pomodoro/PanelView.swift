import PomodoroCore
import SwiftUI

extension Phase {
    var color: Color {
        switch self {
        case .focus: return Color(red: 0xFF / 255, green: 0x5A / 255, blue: 0x36 / 255)
        case .shortBreak: return Color(red: 0x2B / 255, green: 0xB6 / 255, blue: 0x73 / 255)
        case .longBreak: return Color(red: 0x3B / 255, green: 0x82 / 255, blue: 0xF6 / 255)
        }
    }
}

struct PanelView: View {
    @ObservedObject var model: TimerModel

    private var tint: Color { model.phase.color }

    var body: some View {
        VStack(spacing: 0) {
            Text(verbatim: model.phase.title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(tint)
                .accessibilityLabel(model.phase.title)
                .accessibilityValue(model.phase.title)
                .accessibilityIdentifier("phaseLabel")
                .padding(.top, 8)

            ProgressRing(progress: model.progress, tint: tint) {
                VStack(spacing: 4) {
                    Text(model.clock)
                        .font(.system(size: 40, weight: .medium).monospacedDigit())
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(countsDown: true))
                        .accessibilityIdentifier("timeLabel")
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)
            .padding(.top, 16)

            VStack(spacing: 8) {
                Button(action: model.toggle) {
                    Label(model.isRunning ? "Pause" : "Start",
                          systemImage: model.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(tint)
                .capsuleShape()
                .keyboardShortcut(.space, modifiers: [])
                .accessibilityIdentifier("startPauseButton")

                HStack(spacing: 8) {
                    Button(action: model.reset) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!model.canReset)
                    .keyboardShortcut("r", modifiers: .command)
                    .accessibilityIdentifier("resetButton")

                    Button(action: model.skip) {
                        Label("Skip", systemImage: "forward.end")
                            .frame(maxWidth: .infinity)
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    .accessibilityIdentifier("skipButton")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .capsuleShape()
            }
            .padding(.top, 24)

            HStack(spacing: 8) {
                Text("Completed: \(model.completed)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .accessibilityIdentifier("completedLabel")
                Spacer()
                SessionDots(filled: model.sessionsInRound, total: model.sessionsBeforeLongBreak, tint: Phase.focus.color)
            }
            .padding(.top, 16)

            Divider()
                .padding(.top, 16)
                .padding(.bottom, 8)

            HStack {
                Text("Long break after \(model.sessionsBeforeLongBreak) sessions")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(QuietButtonStyle())
                    .keyboardShortcut("q", modifiers: .command)
                    .accessibilityIdentifier("quitButton")
            }
        }
        .padding(16)
        .frame(width: 280)
        .animation(.easeInOut(duration: 0.2), value: model.phase)
        .animation(.easeInOut(duration: 0.15), value: model.isRunning)
    }

    private var statusText: String {
        if model.isRunning { return "Running" }
        return model.showsIdleIcon ? "Ready" : "Paused"
    }
}

private struct ProgressRing<Content: View>: View {
    var progress: Double
    var tint: Color
    @ViewBuilder var content: Content

    private let lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            content
        }
        .padding(lineWidth / 2)
    }
}

private struct SessionDots: View {
    var filled: Int
    var total: Int
    var tint: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < filled ? tint : Color.secondary.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.2), value: filled)
        .accessibilityHidden(true)
    }
}

/// Small plain button with hover and pressed feedback, for secondary actions like Quit.
private struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        QuietButton(configuration: configuration)
    }

    private struct QuietButton: View {
        let configuration: ButtonStyleConfiguration
        @State private var isHovered = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 12))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(configuration.isPressed ? 0.14 : isHovered ? 0.08 : 0))
                )
                .opacity(isEnabled ? 1 : 0.4)
                .onHover { isHovered = $0 }
                .animation(.easeOut(duration: 0.15), value: isHovered)
        }
    }
}

private extension View {
    @ViewBuilder
    func capsuleShape() -> some View {
        if #available(macOS 14.0, *) {
            buttonBorderShape(.capsule)
        } else {
            self
        }
    }
}
