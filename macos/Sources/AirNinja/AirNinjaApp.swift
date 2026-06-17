import SwiftUI

@main
struct AirNinjaApp: App {
    var body: some Scene {
        MenuBarExtra("AirNinja", systemImage: "shippingbox.and.arrow.backward.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
