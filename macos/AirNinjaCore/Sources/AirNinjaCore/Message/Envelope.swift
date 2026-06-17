import Foundation

public struct Envelope<Payload: Codable>: Codable {
    public let v: Int
    public let id: String
    public let type: String
    public let replyTo: String?
    public let ts: Int64
    public let payload: Payload

    public init(v: Int = 1, id: String, type: String, replyTo: String? = nil, ts: Int64, payload: Payload) {
        self.v = v
        self.id = id
        self.type = type
        self.replyTo = replyTo
        self.ts = ts
        self.payload = payload
    }
}

public struct EmptyPayload: Codable, Equatable {
    public init() {}
}

public enum MessageError: Error, Equatable {
    case unexpectedType(String)
}
