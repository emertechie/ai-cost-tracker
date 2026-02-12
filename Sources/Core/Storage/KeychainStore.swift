import Foundation
import Security

/// Stores sensitive credentials (GitHub PAT, API keys) in the macOS Keychain.
///
/// Caches values in memory after the first read to avoid repeated keychain
/// access (which can trigger authorization prompts). Uses `SecItemUpdate`
/// when an item already exists so that the user's "Always Allow" ACL grant
/// is preserved (delete + re-add would reset it).
final class KeychainStore {

    private let service = "com.aicosttracker.credentials"

    /// In-memory cache so we only touch the keychain once per account per
    /// app session (plus on writes).  `nil` value means "we haven't read yet".
    private var cache: [String: String?] = [:]

    // MARK: - GitHub Token

    var gitHubToken: String? {
        get { read(account: "github-token") }
        set {
            if let newValue {
                save(account: "github-token", value: newValue)
            } else {
                delete(account: "github-token")
            }
        }
    }

    // MARK: - Generic Keychain operations

    private func save(account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let searchQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let updateAttributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let status = SecItemUpdate(searchQuery as CFDictionary, updateAttributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist yet — add it.
            var addQuery = searchQuery
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }

        // Update the in-memory cache.
        cache[account] = value
    }

    private func read(account: String) -> String? {
        // Return cached value if we've already read from the keychain.
        if let cached = cache[account] {
            return cached   // may be nil (meaning "no item in keychain")
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let value: String?
        if status == errSecSuccess, let data = result as? Data {
            value = String(data: data, encoding: .utf8)
        } else {
            value = nil
        }

        cache[account] = value
        return value
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        cache[account] = nil as String?
    }
}
