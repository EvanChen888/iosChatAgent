import Foundation

public struct ChatSession: Identifiable, Codable {
    public let id: UUID
    public var title: String
    public var messages: [ChatMessage]
    public let createdAt: Date
    public var updatedAt: Date
    public var selectedModelId: String
    
    public init(id: UUID = UUID(), title: String = "New Chat", messages: [ChatMessage] = [], createdAt: Date = Date(), updatedAt: Date = Date(), selectedModelId: String) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.selectedModelId = selectedModelId
    }
}
