import XCTest
import CryptoKit
import AirNinjaCore

final class NoiseVectorTests: XCTestCase {

    private let handshakeMessageCount = 3

    func testOfficialXxVectorReproducesWireBytesAndHandshakeHash() throws {
        let vector = try loadVector()
        let prologue = TestHex.decode(vector["init_prologue"] as! String)
        let initiatorEphemeral = TestHex.decode(vector["init_ephemeral"] as! String)
        let responderEphemeral = TestHex.decode(vector["resp_ephemeral"] as! String)

        let initiator = try NoiseHandshake(
            role: .initiator,
            identity: try identity(staticPrivateHex: vector["init_static"] as! String),
            prologue: prologue,
            ephemeralProvider: { try! NoiseKeyPair.from(rawPrivate: initiatorEphemeral) }
        )
        let responder = try NoiseHandshake(
            role: .responder,
            identity: try identity(staticPrivateHex: vector["resp_static"] as! String),
            prologue: prologue,
            ephemeralProvider: { try! NoiseKeyPair.from(rawPrivate: responderEphemeral) }
        )

        let messages = vector["messages"] as! [[String: Any]]
        var initiatorTransport: NoiseTransport?
        var responderTransport: NoiseTransport?

        for (index, message) in messages.enumerated() {
            let payload = TestHex.decode(message["payload"] as! String)
            let expected = message["ciphertext"] as! String
            let initiatorIsSender = index % 2 == 0

            if index < handshakeMessageCount {
                let sender = initiatorIsSender ? initiator : responder
                let receiver = initiatorIsSender ? responder : initiator
                let wire = try sender.writeMessage(payload: payload)
                XCTAssertEqual(TestHex.encode(wire), expected, "handshake message \(index)")
                _ = try receiver.readMessage(wire)

                if index == handshakeMessageCount - 1 {
                    XCTAssertEqual(TestHex.encode(initiator.handshakeHash), vector["handshake_hash"] as! String)
                    XCTAssertEqual(TestHex.encode(responder.handshakeHash), vector["handshake_hash"] as! String)
                    initiatorTransport = try initiator.split()
                    responderTransport = try responder.split()
                }
            } else {
                let sender = initiatorIsSender ? initiatorTransport! : responderTransport!
                let receiver = initiatorIsSender ? responderTransport! : initiatorTransport!
                let wire = try sender.encrypt(payload)
                XCTAssertEqual(TestHex.encode(wire), expected, "transport message \(index)")
                _ = try receiver.decrypt(wire)
            }
        }
    }

    private func identity(staticPrivateHex: String) throws -> DeviceIdentity {
        let privateKey = TestHex.decode(staticPrivateHex)
        let publicKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey)
            .publicKey.rawRepresentation
        return try DeviceIdentity.fromRawKeys(privateKey: privateKey, publicKey: publicKey)
    }

    private func loadVector() throws -> [String: Any] {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<8 {
            url.deleteLastPathComponent()
            let candidate = url.appendingPathComponent("shared/conformance/noise_xx_vector.json")
            if FileManager.default.fileExists(atPath: candidate.path) {
                let data = try Data(contentsOf: candidate)
                return try JSONSerialization.jsonObject(with: data) as! [String: Any]
            }
        }
        throw XCTSkip("noise_xx_vector.json not found")
    }
}
