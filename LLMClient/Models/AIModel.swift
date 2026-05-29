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
        AIModel(id: "deepseek-v4-pro", name: "DeepSeek V4 Pro", provider: .deepseek),
        AIModel(id: "deepseek-v4-flash", name: "DeepSeek V4 Flash", provider: .deepseek),
        AIModel(id: "gpt-5.5", name: "GPT-5.5", provider: .openai),
        AIModel(id: "gpt-5.4-mini", name: "GPT-5.4 Mini", provider: .openai),
        AIModel(id: "claude-opus-4-8", name: "Claude Opus 4.8", provider: .claude),
        AIModel(id: "claude-sonnet-4-6", name: "Claude Sonnet 4.6", provider: .claude),
        AIModel(id: "claude-haiku-4-5", name: "Claude Haiku 4.5", provider: .claude),
        AIModel(id: "gemini-3.5-flash", name: "Gemini 3.5 Flash", provider: .gemini),
        AIModel(id: "gemini-3.1-pro-preview", name: "Gemini 3.1 Pro", provider: .gemini)
    ]
}
