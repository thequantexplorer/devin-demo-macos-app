import AppKit
import PomodoroCore
import SwiftUI

/// The menu bar panel. Also hosted in a plain window when launched with `-ui-testing`.
struct PanelView: View {
    @ObservedObject var model: TimerModel

    private var timer: PomodoroTimer { model.timer }
    private var color: Color { timer.phase.color }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.bottom, 16)
            ProgressRing(
                fraction: timer.fractionRemaining,
                isRunning: timer.isRunning,
                color: color,
                time: timer.formattedRemaining,
                caption: caption
            )
            .padding(.bottom, 24)
            controls
                .padding(.bottom, 16)
            footer
        }
        .padding(16)
        .frame(width: 280)
        .background(.regularMaterial)
        .animation(.easeInOut(duration: 0.2), value: timer.phase)
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 6) {
            Circle()
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(timer.phase.title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .accessibilityIdentifier("phaseLabel")
                .contentTransition(.opacity)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
    }

    private var caption: String {
        if timer.isRunning { return "Next: \(timer.upcomingPhase.title)" }
        return timer.isAtPhaseStart ? "Ready" : "Paused"
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Button(action: model.toggle) {
                Label(startPauseTitle, systemImage: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .capsuleShape()
            .tint(color)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("startPauseButton")

            HStack(spacing: 8) {
                Button(action: model.reset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(timer.isAtPhaseStart)
                .help("Back to the start of this phase (⌘R)")
                .accessibilityIdentifier("resetButton")

                Button(action: model.skip) {
                    Label("Skip", systemImage: "forward.end")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .help("Skip to \(skipTarget) (⌘→)")
                .accessibilityIdentifier("skipButton")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .capsuleShape()
        }
    }

    private var startPauseTitle: String {
        if timer.isRunning { return "Pause" }
        return timer.isAtPhaseStart ? "Start" : "Resume"
    }

    private var skipTarget: String {
        timer.phase == .focus ? "a short break" : "Focus"
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Completed: \(timer.completedFocusSessions)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .accessibilityIdentifier("completedLabel")
                Spacer()
                CycleDots(
                    done: timer.completedInCurrentCycle,
                    total: timer.configuration.focusSessionsBeforeLongBreak,
                    color: Phase.focus.color
                )
            }
            .padding(.bottom, 8)

            Divider()

            QuitButton()
        }
    }
}

// MARK: - Pieces

private struct ProgressRing: View {
    let fraction: Double
    let isRunning: Bool
    let color: Color
    let time: String
    let caption: String

    private let size: CGFloat = 160
    private let lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                // Glide continuously between 1 s ticks; snap quickly on Reset / Skip.
                .animation(isRunning ? .linear(duration: 1) : .easeInOut(duration: 0.25), value: fraction)
            VStack(spacing: 4) {
                Text(time)
                    .font(.system(size: 40, weight: .medium))
                    .monospacedDigit()
                    .transaction { $0.animation = nil }
                    .accessibilityIdentifier("timeLabel")
                Text(caption)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Progress towards the next Long break.
private struct CycleDots: View {
    let done: Int
    let total: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < done ? color : Color.primary.opacity(0.12))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(done) of \(total) towards a long break")
        .help("\(done) of \(total) towards a long break")
    }
}

private struct QuitButton: View {
    @State private var isHovered = false

    var body: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            HStack {
                Text("Quit Pomodoro")
                Spacer()
                Text("⌘Q")
                    .foregroundStyle(.tertiary)
            }
            .font(.system(size: 12))
            .foregroundStyle(isHovered ? .primary : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.08 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("q", modifiers: .command)
        .accessibilityIdentifier("quitButton")
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .padding(.horizontal, -8)
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
