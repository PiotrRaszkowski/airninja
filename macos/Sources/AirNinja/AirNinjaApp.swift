import AirNinjaCore
import SwiftUI
import UserNotifications

@main
struct AirNinjaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("AirNinja", systemImage: "shippingbox.and.arrow.backward.fill") {
            MenuBarView(model: appDelegate.controller.model)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        controller.start()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

@MainActor
final class AppController {
    let model = ReceiverModel()
    private var receiver: SmsReceiver?

    func start() {
        guard receiver == nil else { return }
        Notifier.requestAuthorization()
        let receiver = SmsReceiver(identity: DeviceIdentity.generate(), model: model)
        receiver.start()
        self.receiver = receiver
    }
}
