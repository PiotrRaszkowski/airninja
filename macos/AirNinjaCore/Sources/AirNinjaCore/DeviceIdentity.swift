import CryptoKit
import Foundation

public enum DeviceIdentityError: Error {
    case invalidKeyLength
}

public struct DeviceIdentity {
    public let publicKey: Data
    public let privateKey: Data
    public let deviceId: String

    private static let keySize = 32

    private init(privateKey: Data, publicKey: Data) {
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.deviceId = DeviceId.fromPublicKey(publicKey)
    }

    public static func generate() -> DeviceIdentity {
        let key = Curve25519.KeyAgreement.PrivateKey()
        return DeviceIdentity(
            privateKey: key.rawRepresentation,
            publicKey: key.publicKey.rawRepresentation
        )
    }

    public static func fromRawKeys(privateKey: Data, publicKey: Data) throws -> DeviceIdentity {
        guard privateKey.count == keySize, publicKey.count == keySize else {
            throw DeviceIdentityError.invalidKeyLength
        }
        return DeviceIdentity(privateKey: privateKey, publicKey: publicKey)
    }
}
