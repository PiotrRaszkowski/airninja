import XCTest
import AirNinjaCore

final class SmsMessagesTests: XCTestCase {

    private let sample = SmsMessage(
        sender: "+15551234567",
        body: "Hello from Android",
        timestamp: 1718599999000,
        messageId: "sms-42"
    )

    func testEnvelopeRoundTrips() throws {
        let envelope = SmsMessages.envelope(for: sample, id: "env-1", sentAt: 1718600000000)
        let decoded = try SmsMessages.decode(try SmsMessages.encode(envelope))

        XCTAssertEqual(decoded.type, "sms.message")
        XCTAssertEqual(decoded.id, "env-1")
        XCTAssertEqual(decoded.payload, sample)
    }

    func testDecodeRejectsWrongType() throws {
        let wrong = Envelope(id: "x", type: "core.ping", ts: 0, payload: sample)
        let data = try JSONEncoder().encode(wrong)

        XCTAssertThrowsError(try SmsMessages.decode(data)) {
            XCTAssertEqual($0 as? MessageError, .unexpectedType("core.ping"))
        }
    }

    func testDecodesSharedConformanceEnvelope() throws {
        let envelope = try SmsMessages.decode(loadSharedEnvelope())

        XCTAssertEqual(envelope.type, "sms.message")
        XCTAssertEqual(envelope.id, "11111111-1111-4111-8111-111111111111")
        XCTAssertEqual(envelope.payload, sample)
    }

    func testAckEnvelopeReferencesOriginal() {
        let ack = ControlMessages.ackEnvelope(originalId: "env-1", id: "ack-1", sentAt: 1718600001000)

        XCTAssertEqual(ack.type, "core.ack")
        XCTAssertEqual(ack.replyTo, "env-1")
    }

    private func loadSharedEnvelope() throws -> Data {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<8 {
            url.deleteLastPathComponent()
            let candidate = url.appendingPathComponent("shared/conformance/sms_envelope.json")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return try Data(contentsOf: candidate)
            }
        }
        throw XCTSkip("sms_envelope.json not found")
    }
}
