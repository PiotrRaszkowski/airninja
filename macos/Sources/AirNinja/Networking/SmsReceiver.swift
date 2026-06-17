import AirNinjaCore
import Foundation
import Network

/// Advertises `_airninja._tcp`, accepts an incoming connection, runs the Noise XX
/// handshake as responder, then receives `sms.message` frames and acknowledges them.
final class SmsReceiver {
    private let identity: DeviceIdentity
    private let model: ReceiverModel
    private let trustStore: TrustStore
    private let queue = DispatchQueue(label: "com.airninja.receiver")
    private let workers = DispatchQueue(label: "com.airninja.workers", attributes: .concurrent)
    private var listener: NWListener?

    init(identity: DeviceIdentity, model: ReceiverModel, trustStore: TrustStore) {
        self.identity = identity
        self.model = model
        self.trustStore = trustStore
    }

    func start() {
        do {
            let listener = try NWListener(using: .tcp)
            listener.service = NWListener.Service(name: nil, type: "_airninja._tcp")
            listener.stateUpdateHandler = { [weak self] state in self?.handleState(state) }
            listener.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            updateStatus("Failed to start: \(error.localizedDescription)")
        }
    }

    private func handleState(_ state: NWListener.State) {
        switch state {
        case .ready:
            updateStatus("Waiting for device…")
        case .failed(let error):
            updateStatus("Listener failed: \(error.localizedDescription)")
        default:
            break
        }
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        workers.async { [weak self] in self?.runSession(connection) }
    }

    private func runSession(_ connection: NWConnection) {
        let stream = ConnectionStream(connection: connection)
        do {
            let channel = try SecureChannel.handshake(role: .responder, identity: identity, stream: stream)
            guard authorize(channel) else {
                Task { @MainActor in self.model.disconnected() }
                connection.cancel()
                return
            }
            try receiveLoop(channel)
        } catch {
            Task { @MainActor in self.model.disconnected() }
            connection.cancel()
        }
    }

    private func authorize(_ channel: SecureChannel) -> Bool {
        let key = channel.remoteStaticPublicKey
        let deviceId = DeviceId.fromPublicKey(key)
        let sas = channel.sas
        switch trustStore.evaluate(deviceId: deviceId, key: key) {
        case .trusted:
            Task { @MainActor in self.model.paired(sas: sas, peer: deviceId) }
            return true
        case .mismatch:
            Task { @MainActor in self.model.rejectedMismatch(deviceId) }
            return false
        case .unknown:
            guard requestPairingDecision(sas: sas, deviceId: deviceId) else { return false }
            trustStore.trust(deviceId: deviceId, key: key)
            Task { @MainActor in self.model.paired(sas: sas, peer: deviceId) }
            return true
        }
    }

    private func requestPairingDecision(sas: String, deviceId: String) -> Bool {
        if ProcessInfo.processInfo.environment["AIRNINJA_AUTO_PAIR"] == "1" {
            return true
        }
        let semaphore = DispatchSemaphore(value: 0)
        var accepted = false
        let request = PendingPairing(
            sas: sas,
            deviceId: deviceId,
            onAccept: { accepted = true; semaphore.signal() },
            onReject: { semaphore.signal() }
        )
        Task { @MainActor in self.model.requestPairing(request) }
        semaphore.wait()
        Task { @MainActor in self.model.clearPairing() }
        return accepted
    }

    private func receiveLoop(_ channel: SecureChannel) throws {
        while true {
            guard case let .control(payload) = try FrameCodec.decode(channel.receive()) else { continue }
            let envelope = try SmsMessages.decode(payload)
            let message = envelope.payload
            print("RECEIVED SMS from \(message.sender): \(message.body)")
            fflush(stdout)
            Task { @MainActor in
                self.model.received(message)
                Notifier.postSms(message)
            }
            try acknowledge(envelope.id, over: channel)
        }
    }

    private func acknowledge(_ envelopeId: String, over channel: SecureChannel) throws {
        let ack = ControlMessages.ackEnvelope(
            originalId: envelopeId,
            id: UUID().uuidString,
            sentAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        try channel.send(FrameCodec.encode(.control(payload: JSONEncoder().encode(ack))))
    }

    private func updateStatus(_ status: String) {
        Task { @MainActor in self.model.setStatus(status) }
    }
}
