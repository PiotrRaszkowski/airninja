import AirNinjaCore
import Foundation
import UserNotifications

enum Notifier {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func postSms(_ message: SmsMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.sender
        content.body = message.body
        content.sound = .default
        let request = UNNotificationRequest(identifier: message.messageId, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
