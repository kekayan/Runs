import os
import Foundation
import Security
import LocalAuthentication

/// Stores the GitHub token in the Keychain.
///
/// When biometric protection is on, the item is written to the data-protection keychain
/// with a `.biometryCurrentSet` access control, so the Keychain itself refuses to release
/// the token without Touch ID — it is not just a prompt in front of a plain read.
class KeychainManager {
    static let shared = KeychainManager()

    private let service = "dev.kekayan.runs"
    private let account = "github-token"

    private init() {}

    // MARK: - Save

    func saveToken(_ token: String, useBiometric: Bool) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.encodingError
        }

        try deleteToken()

        var query = baseQuery(protected: useBiometric)
        query[kSecValueData as String] = data

        if useBiometric {
            var error: Unmanaged<CFError>?
            guard let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error
            ) else {
                throw KeychainError.accessControlFailed
            }
            query[kSecAttrAccessControl as String] = access
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            Log.keychain.error("Save failed: \(status)")
            throw KeychainError.saveFailed(status)
        }
    }

    // MARK: - Read

    /// Returns the stored token. A biometric-protected token triggers the system Touch ID prompt.
    func getToken(reason: String = "Unlock your GitHub token") async throws -> String? {
        if let token = try await read(protected: true, reason: reason) {
            return token
        }
        return try await read(protected: false, reason: reason)
    }

    private func read(protected: Bool, reason: String) async throws -> String? {
        var query = baseQuery(protected: protected)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        if protected {
            let context = LAContext()
            context.localizedReason = reason
            context.localizedCancelTitle = "Cancel"
            query[kSecUseAuthenticationContext as String] = context
        }

        // SecItemCopyMatching blocks while the Touch ID sheet is up; keep it off the main thread.
        let sendableQuery = query as CFDictionary
        let (status, result) = await Task.detached(priority: .userInitiated) { () -> (OSStatus, Data?) in
            var result: AnyObject?
            let status = SecItemCopyMatching(sendableQuery, &result)
            return (status, result as? Data)
        }.value

        switch status {
        case errSecSuccess:
            guard let data = result, let token = String(data: data, encoding: .utf8) else {
                throw KeychainError.decodingError
            }
            return token
        case errSecItemNotFound:
            return nil
        case errSecUserCanceled, errSecAuthFailed:
            throw KeychainError.biometricAuthenticationFailed
        default:
            Log.keychain.error("Read failed: \(status)")
            throw KeychainError.retrievalFailed(status)
        }
    }

    // MARK: - Delete

    func deleteToken() throws {
        for protected in [true, false] {
            let status = SecItemDelete(baseQuery(protected: protected) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.deletionFailed(status)
            }
        }
    }

    // MARK: - Biometric state

    /// Whether the stored token is the biometric-protected one. Checked without prompting.
    func isBiometricEnabled() -> Bool {
        var query = baseQuery(protected: true)
        let context = LAContext()
        context.interactionNotAllowed = true
        query[kSecUseAuthenticationContext as String] = context
        query[kSecReturnAttributes as String] = true
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    func canUseBiometricAuthentication() -> Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func getBiometricType() -> String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometrics"
        }
    }

    // MARK: - Helpers

    /// Protected tokens live in the data-protection keychain (required for biometric
    /// access control on macOS); unprotected ones in the login keychain as before.
    private func baseQuery(protected: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if protected {
            query[kSecUseDataProtectionKeychain as String] = true
        }
        return query
    }
}

// MARK: - Keychain Errors
enum KeychainError: LocalizedError {
    case encodingError
    case decodingError
    case accessControlFailed
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
    case biometricAuthenticationFailed

    var errorDescription: String? {
        switch self {
        case .encodingError: return "Failed to encode token data"
        case .decodingError: return "Failed to decode token data"
        case .accessControlFailed: return "Failed to create biometric access control"
        case .saveFailed(let status): return "Failed to save to Keychain (status: \(status))"
        case .retrievalFailed(let status): return "Failed to read from Keychain (status: \(status))"
        case .deletionFailed(let status): return "Failed to delete from Keychain (status: \(status))"
        case .biometricAuthenticationFailed: return "Biometric authentication failed or was cancelled"
        }
    }
}
