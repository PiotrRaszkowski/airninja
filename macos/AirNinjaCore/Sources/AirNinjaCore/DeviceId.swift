import Foundation

public enum DeviceId {
    private static let length = 52

    public static func fromPublicKey(_ staticPublicKey: Data) -> String {
        precondition(!staticPublicKey.isEmpty, "Static public key must not be empty")
        let digest = Sha256.hash(staticPublicKey)
        return String(Base32.encodeLowerNoPadding(digest).prefix(length))
    }
}
