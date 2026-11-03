/// The three phases of the Pomodoro cycle.
public enum Phase: String, CaseIterable, Equatable, Sendable {
    case focus
    case shortBreak
    case longBreak

    public var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short break"
        case .longBreak: return "Long break"
        }
    }

    public var isBreak: Bool { self != .focus }
}
