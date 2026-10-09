import Foundation
import Security

nonisolated enum KeychainStore {
    static func read(_ key: String) -> String {
        var query = base(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
    static func write(_ value: String, key: String) throws {
        let query = base(key)
        if value.isEmpty { SecItemDelete(query as CFDictionary); return }
        let attributes: [String: Any] = [kSecValueData as String: Data(value.utf8)]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = Data(value.utf8)
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw StorageError.keychain }
        } else if status != errSecSuccess { throw StorageError.keychain }
    }
    private static func base(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "suri.local", kSecAttrAccount as String: key]
    }
}

nonisolated enum StorageError: Error, LocalizedError {
    case keychain
    var errorDescription: String? { "Could not save this setting securely. Please try again." }
}
