import Foundation

public enum Sas {
    private static let prefix = "AIRNINJA-SAS"
    private static let modulo: UInt32 = 1_000_000

    public static func derive(handshakeHash: Data) -> String {
        var input = Data(prefix.utf8)
        input.append(handshakeHash)
        let digest = Sha256.hash(input)
        let value = (UInt32(digest[0]) << 24)
            | (UInt32(digest[1]) << 16)
            | (UInt32(digest[2]) << 8)
            | UInt32(digest[3])
        return String(format: "%06u", value % modulo)
    }
}
