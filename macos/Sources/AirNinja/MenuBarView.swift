import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: ReceiverModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AirNinja")
                .font(.headline)
            Text(model.status)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let sas = model.pairedSas {
                Text("Pairing code: \(sas)")
                    .font(.caption.monospaced())
            }

            Divider()

            if model.messages.isEmpty {
                Text("No messages yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.messages.prefix(10)) { sms in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sms.sender).font(.caption.bold())
                        Text(sms.body).font(.caption).lineLimit(3)
                    }
                }
            }

            Divider()

            Button("Quit AirNinja") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
