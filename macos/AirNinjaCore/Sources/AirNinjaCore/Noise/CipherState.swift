import CryptoKit
import Foundation

final class CipherState {
    private var key: SymmetricKey?
    private var nonce: UInt64 = 0

    private let tagLength = 16

    var hasKey: Bool { key != nil }

    func initializeKey(_ keyBytes: Data?) {
        key = keyBytes.map { SymmetricKey(data: $0) }
        nonce = 0
    }

    func encryptWithAd(_ ad: Data, _ plaintext: Data) throws -> Data {
        guard let key else { return plaintext }
        let sealed = try ChaChaPoly.seal(plaintext, using: key, nonce: try makeNonce(nonce), authenticating: ad)
        nonce += 1
        return sealed.ciphertext + sealed.tag
    }

    func decryptWithAd(_ ad: Data, _ ciphertext: Data) throws -> Data {
        guard let key else { return ciphertext }
        guard ciphertext.count >= tagLength else { throw NoiseError.malformedCiphertext }
        let body = Data(ciphertext.prefix(ciphertext.count - tagLength))
        let tag = Data(ciphertext.suffix(tagLength))
        let box = try ChaChaPoly.SealedBox(nonce: try makeNonce(nonce), ciphertext: body, tag: tag)
        let plaintext = try ChaChaPoly.open(box, using: key, authenticating: ad)
        nonce += 1
        return plaintext
    }

    private func makeNonce(_ counter: UInt64) throws -> ChaChaPoly.Nonce {
        var data = Data(repeating: 0, count: 4)
        for shift in stride(from: 0, through: 56, by: 8) {
            data.append(UInt8((counter >> UInt64(shift)) & 0xFF))
        }
        return try ChaChaPoly.Nonce(data: data)
    }
}
