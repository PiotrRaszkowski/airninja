import AirNinjaCore
import Foundation
import Security

/// Persists the device's static X25519 private key in the login Keychain so the
/// DeviceId and pairing SAS stay stable across launches.
enum KeychainIdentityStore {
    private static let service = "com.airninja.mac.identity"
    private static let account = "static-x25519"

    static func loadOrCreate() -> DeviceIdentity {
        if let stored = load(), let identity = try? DeviceIdentity.fromPrivateKey(stored) {
            return identity
        }
        let identity = DeviceIdentity.generate()
        save(identity.privateKey)
        return identity
    }

    private static func load() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }

    private static func save(_ data: Data) {
        let identifier: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(identifier as CFDictionary)
        var insert = identifier
        insert[kSecValueData as String] = data
        SecItemAdd(insert as CFDictionary, nil)
    }
}
