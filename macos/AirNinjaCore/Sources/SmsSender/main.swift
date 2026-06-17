import AirNinjaCore
import Foundation
import Network

func discoverEndpoint(timeout: TimeInterval) -> NWEndpoint? {
    let browser = NWBrowser(for: .bonjour(type: "_airninja._tcp", domain: "local."), using: .tcp)
    let semaphore = DispatchSemaphore(value: 0)
    var found: NWEndpoint?
    browser.browseResultsChangedHandler = { results, _ in
        if found == nil, let first = results.first {
            found = first.endpoint
            semaphore.signal()
        }
    }
    browser.start(queue: .global())
    _ = semaphore.wait(timeout: .now() + timeout)
    browser.cancel()
    return found
}

func connect(to endpoint: NWEndpoint, timeout: TimeInterval) -> NWConnection? {
    let connection = NWConnection(to: endpoint, using: .tcp)
    let semaphore = DispatchSemaphore(value: 0)
    var ready = false
    connection.stateUpdateHandler = { state in
        switch state {
        case .ready:
            ready = true
            semaphore.signal()
        case .failed, .cancelled:
            semaphore.signal()
        default:
            break
        }
    }
    connection.start(queue: .global())
    _ = semaphore.wait(timeout: .now() + timeout)
    return ready ? connection : nil
}

func fail(_ message: String, code: Int32) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

let now = Int64(Date().timeIntervalSince1970 * 1000)

guard let endpoint = discoverEndpoint(timeout: 8) else {
    fail("no _airninja._tcp service discovered", code: 1)
}
guard let connection = connect(to: endpoint, timeout: 8) else {
    fail("could not connect to discovered service", code: 2)
}

let stream = ConnectionStream(connection: connection)
do {
    let channel = try SecureChannel.handshake(role: .initiator, identity: DeviceIdentity.generate(), stream: stream)

    let arguments = CommandLine.arguments
    let body = arguments.count > 1 ? arguments[1] : "Hello from the test sender"
    let sender = arguments.count > 2 ? arguments[2] : "+15551234567"
    let sms = SmsMessage(
        sender: sender,
        body: body,
        timestamp: now,
        messageId: "sms-\(now)"
    )
    let envelope = SmsMessages.envelope(for: sms, id: UUID().uuidString, sentAt: now)
    try channel.send(FrameCodec.encode(.control(payload: try SmsMessages.encode(envelope))))

    guard case let .control(ackPayload) = try FrameCodec.decode(channel.receive()) else {
        fail("expected control ack frame", code: 3)
    }
    let ack = try JSONDecoder().decode(Envelope<EmptyPayload>.self, from: ackPayload)
    print("SAS=\(channel.sas)")
    print("SENT messageId=\(sms.messageId); ACK type=\(ack.type) replyTo=\(ack.replyTo ?? "nil")")
    exit(ack.type == "core.ack" ? 0 : 4)
} catch {
    fail("sender error: \(error)", code: 5)
}
