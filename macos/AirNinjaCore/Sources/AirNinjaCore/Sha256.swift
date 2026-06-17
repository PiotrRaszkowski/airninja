import CryptoKit
import Foundation

public enum Sha256 {
    public static func hash(_ data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
}
