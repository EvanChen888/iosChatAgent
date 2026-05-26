import Foundation

public enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case openrouter = "OpenRouter"
    case claude = "Claude"
    case gemini = "Gemini"
    case ollama = "Ollama"
    case deepseek = "DeepSeek"
    
    public var id: String { self.rawValue }
}

public struct AIModel: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let provider: AIProvider
    
    public init(id: String, name: String, provider: AIProvider) {
        self.id = id
        self.name = name
        self.provider = provider
    }
}
