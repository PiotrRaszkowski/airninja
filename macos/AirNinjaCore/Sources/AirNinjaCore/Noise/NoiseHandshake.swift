import Foundation

private enum NoiseToken {
    case e, s, ee, es, se
}

private struct ByteReader {
    private let bytes: [UInt8]
    private var offset = 0

    init(_ data: Data) {
        bytes = [UInt8](data)
    }

    mutating func read(_ count: Int) throws -> Data {
        guard offset + count <= bytes.count else { throw NoiseError.truncatedMessage }
        let slice = bytes[offset..<offset + count]
        offset += count
        return Data(slice)
    }

    mutating func remaining() -> Data {
        let slice = bytes[offset...]
        offset = bytes.count
        return Data(slice)
    }
}

public final class NoiseTransport {
    private let sending: CipherState
    private let receiving: CipherState

    init(sending: CipherState, receiving: CipherState) {
        self.sending = sending
        self.receiving = receiving
    }

    public func encrypt(_ plaintext: Data) throws -> Data {
        try sending.encryptWithAd(Data(), plaintext)
    }

    public func decrypt(_ ciphertext: Data) throws -> Data {
        try receiving.decryptWithAd(Data(), ciphertext)
    }
}

public final class NoiseHandshake {
    private let role: NoiseRole
    private let staticKey: NoiseKeyPair
    private let ephemeralProvider: () -> NoiseKeyPair
    private let symmetric: SymmetricState

    private var ephemeral: NoiseKeyPair?
    private var remoteStatic: Data?
    private var remoteEphemeral: Data?
    private var messageIndex = 0

    private static let messagePatterns: [[NoiseToken]] = [
        [.e],
        [.e, .ee, .s, .es],
        [.s, .se]
    ]

    public init(
        role: NoiseRole,
        identity: DeviceIdentity,
        prologue: Data = Data(),
        ephemeralProvider: @escaping () -> NoiseKeyPair = { NoiseKeyPair.generate() }
    ) throws {
        self.role = role
        self.staticKey = try NoiseKeyPair.from(rawPrivate: identity.privateKey)
        self.ephemeralProvider = ephemeralProvider
        self.symmetric = SymmetricState(protocolName: NoiseProtocol.name)
        self.symmetric.mixHash(prologue)
    }

    public var isComplete: Bool { messageIndex >= NoiseHandshake.messagePatterns.count }

    public func needsWrite() -> Bool {
        !isComplete && (role == .initiator) == writerIsInitiator(messageIndex)
    }

    public func needsRead() -> Bool {
        !isComplete && !needsWrite()
    }

    public var handshakeHash: Data {
        symmetric.hash
    }

    public var localStaticPublicKey: Data {
        staticKey.publicKey
    }

    public var remoteStaticPublicKey: Data? {
        remoteStatic
    }

    public func writeMessage(payload: Data = Data()) throws -> Data {
        guard needsWrite() else { throw NoiseError.unexpectedState }
        var buffer = Data()
        for token in NoiseHandshake.messagePatterns[messageIndex] {
            try writeToken(token, into: &buffer)
        }
        buffer.append(try symmetric.encryptAndHash(payload))
        messageIndex += 1
        return buffer
    }

    public func readMessage(_ message: Data) throws -> Data {
        guard needsRead() else { throw NoiseError.unexpectedState }
        var reader = ByteReader(message)
        for token in NoiseHandshake.messagePatterns[messageIndex] {
            try readToken(token, from: &reader)
        }
        let payload = try symmetric.decryptAndHash(reader.remaining())
        messageIndex += 1
        return payload
    }

    public func split() throws -> NoiseTransport {
        guard isComplete else { throw NoiseError.handshakeIncomplete }
        let (first, second) = symmetric.split()
        return role == .initiator
            ? NoiseTransport(sending: first, receiving: second)
            : NoiseTransport(sending: second, receiving: first)
    }

    private func writerIsInitiator(_ index: Int) -> Bool { index % 2 == 0 }

    private func writeToken(_ token: NoiseToken, into buffer: inout Data) throws {
        switch token {
        case .e:
            let keyPair = ephemeralProvider()
            ephemeral = keyPair
            buffer.append(keyPair.publicKey)
            symmetric.mixHash(keyPair.publicKey)
        case .s:
            buffer.append(try symmetric.encryptAndHash(staticKey.publicKey))
        case .ee, .es, .se:
            symmetric.mixKey(try diffieHellman(for: token))
        }
    }

    private func readToken(_ token: NoiseToken, from reader: inout ByteReader) throws {
        switch token {
        case .e:
            let key = try reader.read(32)
            remoteEphemeral = key
            symmetric.mixHash(key)
        case .s:
            let length = symmetric.cipherState.hasKey ? 48 : 32
            remoteStatic = try symmetric.decryptAndHash(try reader.read(length))
        case .ee, .es, .se:
            symmetric.mixKey(try diffieHellman(for: token))
        }
    }

    private func diffieHellman(for token: NoiseToken) throws -> Data {
        switch token {
        case .ee:
            return try ephemeral!.dh(remotePublic: remoteEphemeral!)
        case .es:
            return role == .initiator
                ? try ephemeral!.dh(remotePublic: remoteStatic!)
                : try staticKey.dh(remotePublic: remoteEphemeral!)
        case .se:
            return role == .initiator
                ? try staticKey.dh(remotePublic: remoteEphemeral!)
                : try ephemeral!.dh(remotePublic: remoteStatic!)
        case .e, .s:
            throw NoiseError.unexpectedState
        }
    }
}
