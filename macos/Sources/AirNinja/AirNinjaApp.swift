import AirNinjaCore
import SwiftUI

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
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.start()
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
