import Foundation

public struct SmsMessage: Codable, Equatable {
    public let sender: String
    public let body: String
    public let timestamp: Int64
    public let messageId: String

    public init(sender: String, body: String, timestamp: Int64, messageId: String) {
        self.sender = sender
        self.body = body
        self.timestamp = timestamp
        self.messageId = messageId
    }
}
