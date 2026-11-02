import Foundation
import PomodoroCore
import UserNotifications

/// Posts the "phase done" notifications. If permission is denied, posting just does nothing.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private var center: UNUserNotificationCenter { .current() }

    func requestPermission() {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func phaseFinished(_ finished: Phase, next: Phase) {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro"
        content.body = Self.message(finished: finished, next: next)
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { _ in }
    }

    static func message(finished: Phase, next: Phase) -> String {
        switch next {
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
