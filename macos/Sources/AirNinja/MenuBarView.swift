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

            if let request = model.pairingRequest {
                pairingPanel(request)
            } else if let sas = model.pairedSas {
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

            if !model.ownDeviceId.isEmpty {
                Text("This Mac: \(model.ownDeviceId.prefix(12))…")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            Button("Quit AirNinja") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func pairingPanel(_ request: PendingPairing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New device wants to pair")
                .font(.caption.bold())
            Text(request.sas)
                .font(.title2.monospaced().bold())
            Text("Confirm this code matches the one shown on your phone.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack {
                Button("Reject", role: .cancel) { request.onReject() }
                Button("Accept") { request.onAccept() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(8)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}
