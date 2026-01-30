import Foundation
import Security
import LocalAuthentication

class KeychainManager {
    static let shared = KeychainManager()

    private let service = "dev.kekayan.runs"
    private let account = "github-token"
    private let biometricFlagKey = "github-token-biometric-enabled"

    private init() {}

    // Save token to Keychain
    func saveToken(_ token: String, useBiometric: Bool = false) throws {
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
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
        
        // Save the biometric preference flag
        saveBiometricPreference(useBiometric)
    }

    // Retrieve token from Keychain with optional biometric authentication
    func getToken(requireBiometric: Bool = false, reason: String = "Authenticate to access GitHub token") async throws -> String? {
        // Check if biometric is required and available
        if requireBiometric && canUseBiometricAuthentication() {
            let authContext = LAContext()
            authContext.localizedCancelTitle = "Cancel"
            
            do {
                let success = try await authContext.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                guard success else {
                    throw KeychainError.biometricAuthenticationFailed
                }
            } catch {
                throw KeychainError.biometricAuthenticationFailed
            }
        }

        // Retrieve token
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

    // Simple token retrieval (for background operations where biometric was already done)
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

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status)
        }
        
        // Clear the biometric preference flag
        clearBiometricPreference()
    }

    // Check if token exists
    func hasToken() -> Bool {
        return (try? getToken()) != nil
    }

    // Check if biometric authentication is available
    func canUseBiometricAuthentication() -> Bool {
        var error: NSError?
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // Get biometric type
    func getBiometricType() -> String {
        let context = LAContext()
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric"
        }
    }
    
    // Save biometric preference
    private func saveBiometricPreference(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: biometricFlagKey)
    }
    
    // Get biometric preference
    func isBiometricEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: biometricFlagKey)
    }
    
    // Clear biometric preference
    private func clearBiometricPreference() {
        UserDefaults.standard.removeObject(forKey: biometricFlagKey)
    }
}

// MARK: - Keychain Errors
enum KeychainError: LocalizedError {
    case encodingError
    case decodingError
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
    case biometricAuthenticationFailed

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
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed or was cancelled"
        }
    }
}
