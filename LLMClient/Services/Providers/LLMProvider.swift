import Foundation

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
        apiKey: String
    ) -> AsyncThrowingStream<String, Error>
}
