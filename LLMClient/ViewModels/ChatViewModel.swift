import Foundation
import SwiftUI

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var session: ChatSession
    @Published public var inputText: String = ""
    @Published public var isGenerating: Bool = false
    
    // For now, default to DeepSeek
    private let defaultModel = AIModel(id: "deepseek-chat", name: "DeepSeek Chat", provider: .deepseek)
    
    public init() {
        let loadedSessions = ChatStorage.shared.loadSessions()
        if let firstSession = loadedSessions.first {
            self.session = firstSession
        } else {
            self.session = ChatSession(selectedModelId: "deepseek-chat")
        }
    }
    
    public func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: inputText)
        session.messages.append(userMessage)
        inputText = ""
        isGenerating = true
        
        // Add empty assistant message to stream into
        let assistantMessage = ChatMessage(role: .assistant, content: "")
        session.messages.append(assistantMessage)
        let messageIndex = session.messages.count - 1
        
        ChatStorage.shared.saveSessions([session])
        
        Task {
            do {
                let apiKey = KeychainManager.shared.get(for: defaultModel.provider) ?? ""
                if apiKey.isEmpty {
                    session.messages[messageIndex].content = "Error: Please configure the API key for \(defaultModel.provider.rawValue) in Settings."
                    isGenerating = false
                    return
                }
                
                let stream = AIService.shared.streamMessage(session.messages, model: defaultModel, apiKey: apiKey)
                for try await chunk in stream {
                    session.messages[messageIndex].content += chunk
                }
            } catch {
                session.messages[messageIndex].content = "Error: \(error.localizedDescription)"
            }
            isGenerating = false
            ChatStorage.shared.saveSessions([session])
        }
    }
}
