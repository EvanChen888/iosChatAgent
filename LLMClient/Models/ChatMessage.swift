import Foundation

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public let role: Role
    public var content: String
    public let timestamp: Date
    public var reasoningContent: String?
    public var tokenUsage: TokenUsage?
    public var cost: Double?
    public var attachments: [ChatAttachment]?
    
    public enum Role: String, Codable, Equatable {
        case system
        case user
        case assistant
    }
    
    public init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), reasoningContent: String? = nil, tokenUsage: TokenUsage? = nil, cost: Double? = nil, attachments: [ChatAttachment]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.reasoningContent = reasoningContent
        self.tokenUsage = tokenUsage
        self.cost = cost
        self.attachments = attachments
    }
}

public struct ChatAttachment: Identifiable, Codable, Equatable {
    public let id: UUID
    public let type: AttachmentType
    public let url: URL?
    public let data: Data?
    public let fileName: String?
    
    public enum AttachmentType: String, Codable, Equatable {
        case image
        case pdf
        case text
        case file
    }
    
    public init(id: UUID = UUID(), type: AttachmentType, url: URL? = nil, data: Data? = nil, fileName: String? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.data = data
        self.fileName = fileName
    }
}
