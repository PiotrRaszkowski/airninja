import AirNinjaCore
import Foundation

struct ReceivedSms: Identifiable, Codable {
    let messageId: String
    let sender: String
    let body: String
    let timestamp: Int64

    var id: String { messageId }
}

@MainActor
final class ReceiverModel: ObservableObject {
    @Published private(set) var ownDeviceId: String = ""
    @Published private(set) var status: String = "Starting…"
    @Published private(set) var pairedSas: String?
    @Published private(set) var peerDeviceId: String?
    @Published private(set) var messages: [ReceivedSms]
    @Published var pairingRequest: PendingPairing?

    private let messageStore: MessageStore

    init(messageStore: MessageStore) {
        self.messageStore = messageStore
        self.messages = messageStore.load()
    }

    func setOwnDeviceId(_ deviceId: String) {
        ownDeviceId = deviceId
    }

    func setStatus(_ status: String) {
        self.status = status
    }

    func requestPairing(_ request: PendingPairing) {
        pairingRequest = request
        status = "New device — confirm pairing code"
    }

    func clearPairing() {
        pairingRequest = nil
    }

    func paired(sas: String, peer: String) {
        pairingRequest = nil
        pairedSas = sas
        peerDeviceId = peer
        status = "Paired with \(peer.prefix(8))…"
    }

    func rejectedMismatch(_ peer: String) {
        pairingRequest = nil
        pairedSas = nil
        status = "Rejected \(peer.prefix(8))… — key changed"
    }

    func disconnected() {
        pairingRequest = nil
        pairedSas = nil
        status = "Waiting for device…"
    }

    func received(_ message: SmsMessage) {
        guard !messages.contains(where: { $0.messageId == message.messageId }) else { return }
        messages.insert(
            ReceivedSms(messageId: message.messageId, sender: message.sender, body: message.body, timestamp: message.timestamp),
            at: 0
        )
        messageStore.save(messages)
    }
}
