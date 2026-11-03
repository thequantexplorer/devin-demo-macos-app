import PomodoroCore
import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension Phase {
    var color: Color {
        switch self {
        case .focus: return Color(hex: 0xFF5A36)
        case .shortBreak: return Color(hex: 0x2BB673)
        case .longBreak: return Color(hex: 0x3B82F6)
        }
    }
}
