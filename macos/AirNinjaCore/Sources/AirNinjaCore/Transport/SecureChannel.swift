import Foundation

public final class SecureChannel {
    private let transport: NoiseTransport
    private let stream: ByteStream

    public let handshakeHash: Data
    public let remoteStaticPublicKey: Data

    public var sas: String { Sas.derive(handshakeHash: handshakeHash) }

    init(transport: NoiseTransport, handshakeHash: Data, remoteStaticPublicKey: Data, stream: ByteStream) {
        self.transport = transport
        self.handshakeHash = handshakeHash
        self.remoteStaticPublicKey = remoteStaticPublicKey
        self.stream = stream
    }

    public func send(_ frame: Data) throws {
        try StreamFraming.writeFrame(stream, try transport.encrypt(frame))
    }

    public func receive() throws -> Data {
        try transport.decrypt(try StreamFraming.readFrame(stream))
    }

    public static func handshake(role: NoiseRole, identity: DeviceIdentity, stream: ByteStream) throws -> SecureChannel {
        let handshake = try NoiseHandshake(role: role, identity: identity)
        while !handshake.isComplete {
            if handshake.needsWrite() {
                try StreamFraming.writeFrame(stream, try handshake.writeMessage())
            } else {
                _ = try handshake.readMessage(try StreamFraming.readFrame(stream))
            }
        }
        guard let remoteStaticPublicKey = handshake.remoteStaticPublicKey else {
            throw NoiseError.handshakeIncomplete
        }
        return SecureChannel(
            transport: try handshake.split(),
            handshakeHash: handshake.handshakeHash,
            remoteStaticPublicKey: remoteStaticPublicKey,
            stream: stream
        )
    }
}
