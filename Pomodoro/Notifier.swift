import Foundation
import UserNotifications
import PomodoroCore

/// Posts local notifications when a phase ends. If permission is denied,
/// posting fails quietly and the timer keeps working.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()

    private var center: UNUserNotificationCenter { .current() }

    override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Posts the message for a phase change that has just led to `newPhase`.
    func phaseEnded(movingTo newPhase: Phase) {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro"
        content.body = Self.message(movingTo: newPhase)
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { _ in }
    }

    static func message(movingTo newPhase: Phase) -> String {
        switch newPhase {
        case .shortBreak: return "Focus done. Time for a short break."
        case .longBreak: return "Focus done. Time for a long break."
        case .focus: return "Break done. Time to focus."
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
