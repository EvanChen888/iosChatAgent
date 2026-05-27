import Foundation

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public let role: Role
    public var content: String
    public let timestamp: Date
    public var tokenUsage: TokenUsage?
    public var cost: Double?
    
    public enum Role: String, Codable, Equatable {
        case system
        case user
        case assistant
    }
    
    public init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), tokenUsage: TokenUsage? = nil, cost: Double? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.tokenUsage = tokenUsage
        self.cost = cost
    }
}
