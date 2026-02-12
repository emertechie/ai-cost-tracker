import Foundation
import Security

/// Stores sensitive credentials (GitHub PAT, API keys) in the macOS Keychain.
final class KeychainStore {

    private let service = "com.aicosttracker.credentials"

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

        // Delete existing first
        delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
