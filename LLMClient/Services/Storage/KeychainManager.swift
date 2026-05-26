import Foundation
import Security

public class KeychainManager {
    public static let shared = KeychainManager()
    
    private init() {}
    
    private func getService() -> String {
        return Bundle.main.bundleIdentifier ?? "com.example.LLMClient"
    }
    
    public func save(key: String, for provider: AIProvider) throws {
        let account = provider.rawValue
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: getService(),
            kSecAttrAccount as String: account
        ]
        
        let data = key.data(using: .utf8)!
        
        // Check if item exists
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // Update existing
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        } else if status == errSecItemNotFound {
            // Add new
            var newQuery = query
            newQuery[kSecValueData as String] = data
            status = SecItemAdd(newQuery as CFDictionary, nil)
        }
        
        if status != errSecSuccess {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
        }
    }
    
    public func get(for provider: AIProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: getService(),
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    public func delete(for provider: AIProvider) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: getService(),
            kSecAttrAccount as String: provider.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
        }
    }
}
