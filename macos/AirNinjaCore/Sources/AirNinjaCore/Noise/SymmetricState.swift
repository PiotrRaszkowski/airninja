import Foundation

final class SymmetricState {
    private(set) var chainingKey: Data
    private(set) var hash: Data
    let cipherState = CipherState()

    private let hashLength = 32

    init(protocolName: String) {
        let nameData = Data(protocolName.utf8)
        if nameData.count <= hashLength {
            hash = nameData + Data(repeating: 0, count: hashLength - nameData.count)
        } else {
            hash = Sha256.hash(nameData)
        }
        chainingKey = hash
        cipherState.initializeKey(nil)
    }

    func mixKey(_ ikm: Data) {
        let outputs = NoiseHkdf.derive(chainingKey: chainingKey, ikm: ikm, numOutputs: 2)
        chainingKey = outputs[0]
        cipherState.initializeKey(outputs[1])
    }

    func mixHash(_ data: Data) {
        hash = Sha256.hash(hash + data)
    }

    func encryptAndHash(_ plaintext: Data) throws -> Data {
        let ciphertext = try cipherState.encryptWithAd(hash, plaintext)
        mixHash(ciphertext)
        return ciphertext
    }

    func decryptAndHash(_ ciphertext: Data) throws -> Data {
        let plaintext = try cipherState.decryptWithAd(hash, ciphertext)
        mixHash(ciphertext)
        return plaintext
    }

    func split() -> (CipherState, CipherState) {
        let outputs = NoiseHkdf.derive(chainingKey: chainingKey, ikm: Data(), numOutputs: 2)
        let first = CipherState()
        first.initializeKey(outputs[0])
        let second = CipherState()
        second.initializeKey(outputs[1])
        return (first, second)
    }
}
