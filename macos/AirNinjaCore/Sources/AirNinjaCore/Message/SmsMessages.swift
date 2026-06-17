import Foundation

public enum SmsMessages {
    public static let type = "sms.message"

    public static func envelope(for message: SmsMessage, id: String, sentAt: Int64) -> Envelope<SmsMessage> {
        Envelope(id: id, type: type, ts: sentAt, payload: message)
    }

    public static func encode(_ envelope: Envelope<SmsMessage>) throws -> Data {
        try JSONEncoder().encode(envelope)
    }

    public static func decode(_ data: Data) throws -> Envelope<SmsMessage> {
        let envelope = try JSONDecoder().decode(Envelope<SmsMessage>.self, from: data)
        guard envelope.type == type else { throw MessageError.unexpectedType(envelope.type) }
        return envelope
    }
}

public enum ControlMessages {
    public static let ack = "core.ack"

    public static func ackEnvelope(originalId: String, id: String, sentAt: Int64) -> Envelope<EmptyPayload> {
        Envelope(id: id, type: ack, replyTo: originalId, ts: sentAt, payload: EmptyPayload())
    }
}
