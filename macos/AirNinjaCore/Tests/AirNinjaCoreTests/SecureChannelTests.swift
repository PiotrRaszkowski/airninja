import XCTest
import AirNinjaCore

final class SecureChannelTests: XCTestCase {

    func testHandshakeOverStreamsEstablishesMatchingChannelAndTransfersFrames() throws {
        let alice = DeviceIdentity.generate()
        let bob = DeviceIdentity.generate()
        let aliceToBob = BlockingPipe()
        let bobToAlice = BlockingPipe()
        let initiatorStream = PipeStream(inbound: bobToAlice, outbound: aliceToBob)
        let responderStream = PipeStream(inbound: aliceToBob, outbound: bobToAlice)

        var responder: SecureChannel?
        var responderError: Error?
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            do {
                responder = try SecureChannel.handshake(role: .responder, identity: bob, stream: responderStream)
            } catch {
                responderError = error
            }
            group.leave()
        }

        let initiator = try SecureChannel.handshake(role: .initiator, identity: alice, stream: initiatorStream)
        group.wait()
        XCTAssertNil(responderError)
        let responderChannel = try XCTUnwrap(responder)

        try initiator.send(FrameCodec.encode(.control(payload: Data("sms from android".utf8))))
        let receivedByResponder = try FrameCodec.decode(responderChannel.receive())
        try responderChannel.send(FrameCodec.encode(.control(payload: Data("ack from macos".utf8))))
        let receivedByInitiator = try FrameCodec.decode(initiator.receive())

        XCTAssertEqual(initiator.sas, responderChannel.sas)
        XCTAssertEqual(initiator.remoteStaticPublicKey, bob.publicKey)
        XCTAssertEqual(responderChannel.remoteStaticPublicKey, alice.publicKey)
        XCTAssertEqual(receivedByResponder, .control(payload: Data("sms from android".utf8)))
        XCTAssertEqual(receivedByInitiator, .control(payload: Data("ack from macos".utf8)))
    }
}

private final class BlockingPipe {
    private let condition = NSCondition()
    private var buffer = Data()
    private var closed = false

    func write(_ data: Data) {
        condition.lock()
        buffer.append(data)
        condition.signal()
        condition.unlock()
    }

    func read(_ count: Int) throws -> Data {
        condition.lock()
        defer { condition.unlock() }
        while buffer.count < count {
            if closed { throw TransportError.streamClosed }
            condition.wait()
        }
        let out = Data(buffer.prefix(count))
        buffer.removeFirst(count)
        return out
    }
}

private final class PipeStream: ByteStream {
    private let inbound: BlockingPipe
    private let outbound: BlockingPipe

    init(inbound: BlockingPipe, outbound: BlockingPipe) {
        self.inbound = inbound
        self.outbound = outbound
    }

    func readExact(_ count: Int) throws -> Data {
        try inbound.read(count)
    }

    func write(_ data: Data) throws {
        outbound.write(data)
    }
}
