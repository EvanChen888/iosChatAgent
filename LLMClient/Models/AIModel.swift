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

extension AIModel {
    public static let availableModels: [AIModel] = [
        AIModel(id: "deepseek-chat", name: "DeepSeek Chat", provider: .deepseek),
        AIModel(id: "deepseek-reasoner", name: "DeepSeek Reasoner", provider: .deepseek),
        AIModel(id: "gpt-4o", name: "GPT-4o", provider: .openai),
        AIModel(id: "gpt-4o-mini", name: "GPT-4o Mini", provider: .openai),
        AIModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet", provider: .claude)
    ]
}
