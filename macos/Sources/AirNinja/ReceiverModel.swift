import AirNinjaCore
import Foundation

struct ReceivedSms: Identifiable {
    let id = UUID()
    let sender: String
    let body: String
    let timestamp: Int64
}

@MainActor
final class ReceiverModel: ObservableObject {
    @Published private(set) var status: String = "Starting…"
    @Published private(set) var pairedSas: String?
    @Published private(set) var messages: [ReceivedSms] = []

    func setStatus(_ status: String) {
        self.status = status
    }

    func paired(sas: String) {
        pairedSas = sas
        status = "Paired · SAS \(sas)"
    }

    func disconnected() {
        pairedSas = nil
        status = "Waiting for device…"
    }

    func received(_ message: SmsMessage) {
        messages.insert(
            ReceivedSms(sender: message.sender, body: message.body, timestamp: message.timestamp),
            at: 0
        )
    }
}
