import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    // New primary service name after rename
    let service = "LLMKeyring"
    // Legacy service name for backward-compatibility reads/deletes
    private let legacyService = "LLMManager"

    func save(secret: String, account: String) throws {
        let data = Data(secret.utf8)
        // Delete existing if any
        _ = try? delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.os(status) }
    }

    func read(account: String) throws -> String? {
        // First try new service
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            // Fallback to legacy service
            query[kSecAttrService as String] = legacyService
            result = nil
            let legacyStatus = SecItemCopyMatching(query as CFDictionary, &result)
            if legacyStatus == errSecItemNotFound { return nil }
            guard legacyStatus == errSecSuccess else { throw KeychainError.os(legacyStatus) }
            if let data = result as? Data { return String(data: data, encoding: .utf8) }
            return nil
        }
        guard status == errSecSuccess else { throw KeychainError.os(status) }
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.os(status)
        }
        // Best-effort delete legacy item as well
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: legacyService,
            kSecAttrAccount as String: account
        ]
        _ = SecItemDelete(legacyQuery as CFDictionary)
    }
    
    func deleteAll() throws {
        // Delete all items for the current service
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.os(status)
        }
        // Best-effort delete all legacy items as well
        let legacyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: legacyService
        ]
        _ = SecItemDelete(legacyQuery as CFDictionary)
    }
}

enum KeychainError: Error, LocalizedError {
    case os(OSStatus)
    var errorDescription: String? {
        switch self {
        case .os(let status):
            if let message = SecCopyErrorMessageString(status, nil) as String? { return message }
            return "Keychain error: \(status)"
        }
    }
}
