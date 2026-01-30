import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.yourcompany.runs"
    private let account = "github-token"

    private init() {}

    // Save token to Keychain
    func saveToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.encodingError
        }

        // First, try to delete any existing token
        try? deleteToken()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    // Retrieve token from Keychain
    func getToken() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.retrievalFailed(status)
        }

        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingError
        }

        return token
    }

    // Delete token from Keychain
    func deleteToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        // It's OK if the item doesn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status)
        }
    }

    // Check if token exists
    func hasToken() -> Bool {
        return (try? getToken()) != nil
    }
}

// MARK: - Keychain Errors
enum KeychainError: LocalizedError {
    case encodingError
    case decodingError
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingError:
            return "Failed to encode token data"
        case .decodingError:
            return "Failed to decode token data"
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .retrievalFailed(let status):
            return "Failed to retrieve from Keychain (status: \(status))"
        case .deletionFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        }
    }
}
