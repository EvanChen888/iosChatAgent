import Foundation

public class ClaudeProvider: LLMProvider {
    public let providerId: AIProvider = .claude
    
    public init() {}
    
    public func sendMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "Response from Claude (\(model.name))"
    }
    
    public func streamMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                let text = "Streaming response from Claude..."
                for char in text {
                    try await Task.sleep(nanoseconds: 50_000_000)
                    continuation.yield(String(char))
                }
                continuation.finish()
            }
        }
    }
}
