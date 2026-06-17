import XCTest
import AirNinjaCore

final class NoiseHandshakeTests: XCTestCase {

    func testXxHandshakeDerivesEqualHandshakeHashAndSas() throws {
        let session = try performXxHandshake()
        XCTAssertEqual(session.initiator.handshakeHash, session.responder.handshakeHash)
        XCTAssertEqual(
            Sas.derive(handshakeHash: session.initiator.handshakeHash),
            Sas.derive(handshakeHash: session.responder.handshakeHash)
        )
    }

    func testXxHandshakeExchangesStaticKeysForPinning() throws {
        let session = try performXxHandshake()
        XCTAssertEqual(session.initiator.localStaticPublicKey, session.alice.publicKey)
        XCTAssertEqual(session.initiator.remoteStaticPublicKey, session.bob.publicKey)
        XCTAssertEqual(session.responder.remoteStaticPublicKey, session.alice.publicKey)
    }

    func testTransportEncryptsAndDecryptsBothDirections() throws {
        let session = try performXxHandshake()
        let initiatorTransport = try session.initiator.split()
        let responderTransport = try session.responder.split()

        let fromInitiator = try initiatorTransport.encrypt(Data("sms from android".utf8))
        let fromResponder = try responderTransport.encrypt(Data("ack from macos".utf8))

        XCTAssertEqual(try responderTransport.decrypt(fromInitiator), Data("sms from android".utf8))
        XCTAssertEqual(try initiatorTransport.decrypt(fromResponder), Data("ack from macos".utf8))
    }

    func testTransportRejectsTamperedCiphertext() throws {
        let session = try performXxHandshake()
        let initiatorTransport = try session.initiator.split()
        let responderTransport = try session.responder.split()
        var ciphertext = try initiatorTransport.encrypt(Data("secret".utf8))

        ciphertext[ciphertext.count - 1] ^= 0x01

        XCTAssertThrowsError(try responderTransport.decrypt(ciphertext))
    }

    private struct EstablishedSession {
        let alice: DeviceIdentity
        let bob: DeviceIdentity
        let initiator: NoiseHandshake
        let responder: NoiseHandshake
    }

    private func performXxHandshake() throws -> EstablishedSession {
        let alice = DeviceIdentity.generate()
        let bob = DeviceIdentity.generate()
        let initiator = try NoiseHandshake(role: .initiator, identity: alice)
        let responder = try NoiseHandshake(role: .responder, identity: bob)

        _ = try responder.readMessage(try initiator.writeMessage())
        _ = try initiator.readMessage(try responder.writeMessage())
        _ = try responder.readMessage(try initiator.writeMessage())

        return EstablishedSession(alice: alice, bob: bob, initiator: initiator, responder: responder)
    }
}
