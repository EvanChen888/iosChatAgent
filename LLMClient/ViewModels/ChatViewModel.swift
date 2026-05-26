import Foundation
import SwiftUI

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var sessions: [ChatSession] = []
    @Published public var selectedSessionId: UUID?
    
    @Published public var inputText: String = ""
    @Published public var isGenerating: Bool = false
    
    // For now, default to DeepSeek
    private let defaultModel = AIModel(id: "deepseek-chat", name: "DeepSeek Chat", provider: .deepseek)
    
    public init() {
        let loadedSessions = ChatStorage.shared.loadSessions()
        self.sessions = loadedSessions
        
        if let firstSession = loadedSessions.first {
            self.selectedSessionId = firstSession.id
        } else {
            createNewChat()
        }
    }
    
    public var activeSessionIndex: Int? {
        sessions.firstIndex(where: { $0.id == selectedSessionId })
    }
    
    public func createNewChat() {
        let newSession = ChatSession(selectedModelId: "deepseek-chat")
        sessions.insert(newSession, at: 0)
        selectedSessionId = newSession.id
        saveSessions()
    }
    
    public func deleteChat(at offsets: IndexSet) {
        let sessionIdsToDelete = offsets.map { sessions[$0].id }
        sessions.remove(atOffsets: offsets)
        
        if let currentId = selectedSessionId, sessionIdsToDelete.contains(currentId) {
            selectedSessionId = sessions.first?.id
        }
        
        if sessions.isEmpty {
            createNewChat()
        }
        
        saveSessions()
    }
    
    private func saveSessions() {
        ChatStorage.shared.saveSessions(sessions)
    }
    
    public func sendMessage() {
        guard let index = activeSessionIndex else { return }
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: inputText)
        sessions[index].messages.append(userMessage)
        inputText = ""
        isGenerating = true
        
        // Add empty assistant message to stream into
        let assistantMessage = ChatMessage(role: .assistant, content: "")
        sessions[index].messages.append(assistantMessage)
        let messageIndex = sessions[index].messages.count - 1
        
        saveSessions()
        
        Task {
            do {
                let apiKey = KeychainManager.shared.get(for: defaultModel.provider) ?? ""
                if apiKey.isEmpty {
                    sessions[index].messages[messageIndex].content = "Error: Please configure the API key for \(defaultModel.provider.rawValue) in Settings."
                    isGenerating = false
                    return
                }
                
                let stream = AIService.shared.streamMessage(sessions[index].messages, model: defaultModel, apiKey: apiKey)
                for try await chunk in stream {
                    // Re-fetch index in case it changed during async
                    if let currentIndex = activeSessionIndex {
                        sessions[currentIndex].messages[messageIndex].content += chunk
                    }
                }
            } catch {
                if let currentIndex = activeSessionIndex {
                    sessions[currentIndex].messages[messageIndex].content = "Error: \(error.localizedDescription)"
                }
            }
            isGenerating = false
            saveSessions()
        }
    }
}
