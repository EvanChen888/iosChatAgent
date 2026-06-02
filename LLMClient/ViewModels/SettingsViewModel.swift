import Foundation
import Combine

@MainActor
public class SettingsViewModel: ObservableObject {
    @Published public var providerConfigured: [AIProvider: Bool] = [:]
    
    public init() {
        refreshStatus()
    }
    
    public func refreshStatus() {
        Task.detached {
            var status: [AIProvider: Bool] = [:]
            for provider in AIProvider.allCases {
                let key = KeychainManager.shared.get(for: provider)
                status[provider] = (key?.isEmpty == false)
            }
            await MainActor.run {
                self.providerConfigured = status
            }
        }
    }
    
    public func saveKey(_ key: String, for provider: AIProvider) {
        do {
            if key.isEmpty {
                try KeychainManager.shared.delete(for: provider)
            } else {
                try KeychainManager.shared.save(key: key, for: provider)
            }
            refreshStatus()
        } catch {
            print("Failed to save key to keychain: \(error)")
        }
    }
    
    public func getKey(for provider: AIProvider) -> String {
        return KeychainManager.shared.get(for: provider) ?? ""
    }
}
