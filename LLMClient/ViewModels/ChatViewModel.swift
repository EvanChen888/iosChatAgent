import Foundation
import SwiftUI

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var sessions: [ChatSession] = []
    @Published public var selectedSessionId: UUID?
    
    @Published public var inputText: String = ""
    @Published public var isGenerating: Bool = false
    @Published public var pendingAttachments: [ChatAttachment] = []
    @Published public var previewImage: UIImage? = nil
    @Published public var selectedAttachment: ChatAttachment? = nil
    @Published public var pdfVisionMode: Bool = false
    
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
    
    public var activeModel: AIModel? {
        guard let index = activeSessionIndex else { return nil }
        let modelId = sessions[index].selectedModelId
        return AIModel.availableModels.first(where: { $0.id == modelId }) ?? AIModel.availableModels.first
    }
    
    public func setModel(for sessionId: UUID, modelId: String) {
        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[index].selectedModelId = modelId
            saveSessions()
        }
    }
    
    public func createNewChat() {
        let newSession = ChatSession(selectedModelId: "deepseek-v4-flash")
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
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pendingAttachments.isEmpty else { return }
        
        let targetSessionId = sessions[index].id
        let currentInput = inputText
        let currentAttachments = pendingAttachments
        let isPdfVision = pdfVisionMode
        
        inputText = ""
        pendingAttachments = []
        isGenerating = true
        
        guard let model = activeModel else { return }
        
        Task {
            // Process PDF attachments on a background thread to prevent UI freezing
            let processedAttachments = await Task.detached {
                var processed: [ChatAttachment] = []
                for attachment in currentAttachments {
                    if attachment.type == .pdf, let data = attachment.data {
                        if isPdfVision {
                            if let imagesData = PDFExtractor.convertToImages(from: data) {
                                for imgData in imagesData {
                                    processed.append(ChatAttachment(type: .image, data: imgData, fileName: attachment.fileName))
                                }
                            }
                        } else {
                            processed.append(attachment)
                        }
                    } else {
                        processed.append(attachment)
                    }
                }
                return processed
            }.value
            
            guard let currentIndex = self.sessions.firstIndex(where: { $0.id == targetSessionId }) else { return }
            
            let userMessage = ChatMessage(role: .user, content: currentInput, attachments: processedAttachments.isEmpty ? nil : processedAttachments)
            self.sessions[currentIndex].messages.append(userMessage)
            
            // Add empty assistant message to stream into
            let assistantMessage = ChatMessage(role: .assistant, content: "")
            self.sessions[currentIndex].messages.append(assistantMessage)
            let messageIndex = self.sessions[currentIndex].messages.count - 1

            let apiKey = KeychainManager.shared.get(for: model.provider) ?? ""
            if apiKey.isEmpty {
                if let currentIndex = self.sessions.firstIndex(where: { $0.id == targetSessionId }) {
                    sessions[currentIndex].messages[messageIndex].content = "Error: Please configure the API key for \(model.provider.rawValue) in Settings."
                    isGenerating = false
                }
                return
            }
            
            do {
                let stream = AIService.shared.streamMessage(sessions[index].messages, model: model, apiKey: apiKey) { tokenUsage in
                    Task { @MainActor in
                        if let currentIndex = self.sessions.firstIndex(where: { $0.id == targetSessionId }) {
                            self.sessions[currentIndex].messages[messageIndex].tokenUsage = tokenUsage
                            self.sessions[currentIndex].messages[messageIndex].cost = PricingConfig.calculateCost(modelId: model.id, usage: tokenUsage)
                        }
                    }
                }
                var accumulatedText = ""
                var accumulatedReasoning = ""
                var lastUpdateTime = Date()
                
                for try await event in stream {
                    switch event {
                    case .text(let text):
                        accumulatedText += text
                    case .reasoning(let text):
                        accumulatedReasoning += text
                    }
                    
                    if Date().timeIntervalSince(lastUpdateTime) > 0.03 {
                        if let currentIndex = self.sessions.firstIndex(where: { $0.id == targetSessionId }) {
                            if !accumulatedText.isEmpty {
                                sessions[currentIndex].messages[messageIndex].content += accumulatedText
                                accumulatedText = ""
                            }
                            if !accumulatedReasoning.isEmpty {
                                if sessions[currentIndex].messages[messageIndex].reasoningContent == nil {
                                    sessions[currentIndex].messages[messageIndex].reasoningContent = ""
                                }
                                sessions[currentIndex].messages[messageIndex].reasoningContent? += accumulatedReasoning
                                accumulatedReasoning = ""
                            }
                        }
                        lastUpdateTime = Date()
                    }
                }
                
                // Flush remaining text
                if let currentIndex = self.sessions.firstIndex(where: { $0.id == targetSessionId }) {
                    if !accumulatedText.isEmpty {
                        sessions[currentIndex].messages[messageIndex].content += accumulatedText
                    }
                    if !accumulatedReasoning.isEmpty {
                        if sessions[currentIndex].messages[messageIndex].reasoningContent == nil {
                            sessions[currentIndex].messages[messageIndex].reasoningContent = ""
                        }
                        sessions[currentIndex].messages[messageIndex].reasoningContent? += accumulatedReasoning
                    }
                }
            } catch {
                if let currentIndex = self.sessions.firstIndex(where: { $0.id == targetSessionId }) {
                    sessions[currentIndex].messages[messageIndex].content = "Error: \(error.localizedDescription)"
                }
            }
            isGenerating = false
            saveSessions()
            
            // Auto-generate title for new chats
            if let currentIndex = self.sessions.firstIndex(where: { $0.id == targetSessionId }), sessions[currentIndex].title == "New Chat", let firstUserMsg = sessions[currentIndex].messages.first(where: { $0.role == .user }) {
                let msgContent = firstUserMsg.content
                generateSummaryTitle(for: targetSessionId, firstMessage: msgContent, model: model, apiKey: apiKey)
            }
        }
    }
    
    private func generateSummaryTitle(for sessionId: UUID, firstMessage: String, model: AIModel, apiKey: String) {
        Task {
            do {
                let trimmedMsg = firstMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedMsg.isEmpty {
                    updateSessionTitle(sessionId: sessionId, title: "Image Message")
                    return
                }
                
                try await Task.sleep(nanoseconds: 1_500_000_000)
                
                let messages = [
                    ChatMessage(role: .system, content: "You are a title generator. Return only the short title. No quotes, no intro, no punctuation."),
                    ChatMessage(role: .user, content: "Summarize this into a short, concise chat title (maximum 4 words):\n\n\(trimmedMsg)")
                ]
                
                let generatedTitle = try await AIService.shared.sendMessage(messages, model: model, apiKey: apiKey)
                
                // Strip out reasoning blocks (e.g. from DeepSeek or Claude)
                var cleanTitle = generatedTitle
                if let endThinkRange = cleanTitle.range(of: "</think>") {
                    cleanTitle = String(cleanTitle[endThinkRange.upperBound...])
                }
                
                var finalTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'.!?")))
                
                if finalTitle.isEmpty || finalTitle.count > 30 {
                    finalTitle = String(trimmedMsg.prefix(15)) + (trimmedMsg.count > 15 ? "..." : "")
                }
                
                updateSessionTitle(sessionId: sessionId, title: finalTitle)
            } catch {
                print("Failed to generate title: \(error)")
                let trimmedMsg = firstMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedMsg.isEmpty {
                    let fallbackTitle = String(trimmedMsg.prefix(15)) + (trimmedMsg.count > 15 ? "..." : "")
                    updateSessionTitle(sessionId: sessionId, title: fallbackTitle)
                }
            }
        }
    }
    
    @MainActor
    private func updateSessionTitle(sessionId: UUID, title: String) {
        if let index = self.sessions.firstIndex(where: { $0.id == sessionId }) {
            self.sessions[index].title = title
            self.saveSessions()
        }
    }
}
