import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AirNinja")
                .font(.headline)
            Text("No devices paired yet.")
                .foregroundStyle(.secondary)
            Divider()
            Button("Quit AirNinja") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 260)
    }
}

#Preview {
    MenuBarView()
}
