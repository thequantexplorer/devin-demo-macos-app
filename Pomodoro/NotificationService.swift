import Foundation
import PomodoroCore
import UserNotifications

/// Posts a local notification when a phase runs out. Everything here is
/// best-effort: if notifications are denied or off, the timer keeps working.
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private var center: UNUserNotificationCenter { .current() }

    func requestAuthorization() {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func postCompletion(_ completion: PhaseCompletion, configuration: PomodoroConfiguration) {
        guard !LaunchOptions.isUITesting else { return }
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            let content = UNMutableNotificationContent()
            content.title = Self.title(for: completion)
            content.body = Self.body(for: completion, configuration: configuration)
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request) { _ in }
        }
    }

    static func title(for completion: PhaseCompletion) -> String {
        switch completion.finished {
        case .focus: return "Focus complete"
        case .shortBreak, .longBreak: return "Break's over"
        }
    }

    static func body(for completion: PhaseCompletion, configuration: PomodoroConfiguration) -> String {
        let minutes = Int((configuration.duration(of: completion.next) / 60).rounded())
        switch completion.next {
        case .focus:
            return "Back to focus for \(minutes) minutes."
        case .shortBreak:
            return "Nice work. Take a \(minutes)-minute short break."
        case .longBreak:
            return "\(completion.completedFocusSessions) sessions done. Enjoy a \(minutes)-minute long break."
        }
    }

    // Show banners even while the panel is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
