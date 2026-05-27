import Foundation

public enum StreamEvent {
    case text(String)
    case reasoning(String)
}

public protocol LLMProvider {
    var providerId: AIProvider { get }
    
    func sendMessage(
        _ messages: [ChatMessage],
        model: AIModel,
        apiKey: String
    ) async throws -> String
    
    func streamMessage(
        _ messages: [ChatMessage],
        model: AIModel,
        apiKey: String,
        onUsageUpdate: @escaping (TokenUsage) -> Void
    ) -> AsyncThrowingStream<StreamEvent, Error>
}
