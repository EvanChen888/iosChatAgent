import Foundation
import SwiftUI

@MainActor
public class AIService: ObservableObject {
    public static let shared = AIService()
    
    private var providers: [AIProvider: LLMProvider] = [
        .openai: OpenAIProvider(),
        .claude: ClaudeProvider(),
        .deepseek: DeepSeekProvider(),
        .gemini: GeminiProvider()
        // Other providers can be registered here
    ]
    
    private init() {}
    
    public func sendMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String) async throws -> String {
        guard let provider = providers[model.provider] else {
            throw NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Provider not found"])
        }
        return try await provider.sendMessage(messages, model: model, apiKey: apiKey)
    }
    
    public func streamMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String, onUsageUpdate: @escaping (TokenUsage) -> Void) -> AsyncThrowingStream<StreamEvent, Error> {
        guard let provider = providers[model.provider] else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: NSError(domain: "AIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Provider not found"]))
            }
        }
        return provider.streamMessage(messages, model: model, apiKey: apiKey, onUsageUpdate: onUsageUpdate)
    }
}
