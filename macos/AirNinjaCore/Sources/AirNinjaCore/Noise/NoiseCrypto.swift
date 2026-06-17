import CryptoKit
import Foundation

public enum NoiseProtocol {
    public static let name = "Noise_XX_25519_ChaChaPoly_SHA256"
}

public enum NoiseRole {
    case initiator
    case responder
}

public enum NoiseError: Error, Equatable {
    case unexpectedState
    case truncatedMessage
    case malformedCiphertext
    case handshakeIncomplete
}

public struct NoiseKeyPair {
    let privateKey: Curve25519.KeyAgreement.PrivateKey

    public var publicKey: Data { privateKey.publicKey.rawRepresentation }

    public static func generate() -> NoiseKeyPair {
        NoiseKeyPair(privateKey: Curve25519.KeyAgreement.PrivateKey())
    }

    public static func from(rawPrivate: Data) throws -> NoiseKeyPair {
        NoiseKeyPair(privateKey: try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: rawPrivate))
    }

    func dh(remotePublic: Data) throws -> Data {
        let peer = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: remotePublic)
        let secret = try privateKey.sharedSecretFromKeyAgreement(with: peer)
        return secret.withUnsafeBytes { Data($0) }
    }
}

enum NoiseHkdf {
    static func derive(chainingKey: Data, ikm: Data, numOutputs: Int) -> [Data] {
        let tempKey = hmac(key: chainingKey, data: ikm)
        let output1 = hmac(key: tempKey, data: Data([0x01]))
        let output2 = hmac(key: tempKey, data: output1 + Data([0x02]))
        if numOutputs == 2 {
            return [output1, output2]
        }
        let output3 = hmac(key: tempKey, data: output2 + Data([0x03]))
        return [output1, output2, output3]
    }

    private static func hmac(key: Data, data: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: key)))
    }
}
