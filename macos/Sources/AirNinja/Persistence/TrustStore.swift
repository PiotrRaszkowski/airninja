import Foundation

/// Remembers paired peers by `deviceId → static public key` so a known device
/// reconnects silently, while a changed key for a known deviceId is rejected (MITM defense).
final class TrustStore {
    enum Evaluation {
        case trusted
        case mismatch
        case unknown
    }

    private let url = AppSupport.directory().appendingPathComponent("trusted-peers.json")
    private let lock = NSLock()
    private var trusted: [String: String]

    init() {
        trusted = TrustStore.read(url)
    }

    func evaluate(deviceId: String, key: Data) -> Evaluation {
        lock.lock()
        defer { lock.unlock() }
        guard let stored = trusted[deviceId] else { return .unknown }
        return stored == key.base64EncodedString() ? .trusted : .mismatch
    }

    func trust(deviceId: String, key: Data) {
        lock.lock()
        trusted[deviceId] = key.base64EncodedString()
        let snapshot = trusted
        lock.unlock()
        write(snapshot)
    }

    private func write(_ snapshot: [String: String]) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func read(_ url: URL) -> [String: String] {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
