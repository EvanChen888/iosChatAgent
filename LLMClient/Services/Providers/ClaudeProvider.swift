import Foundation

public class ClaudeProvider: LLMProvider {
    public let providerId: AIProvider = .claude
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    public init() {}
    
    struct AnthropicMessage: Codable {
        let role: String
        let content: String
    }
    
    struct AnthropicRequest: Codable {
        let model: String
        let max_tokens: Int
        let system: String?
        let messages: [AnthropicMessage]
        let stream: Bool
    }
    
    struct AnthropicUsage: Codable {
        let input_tokens: Int?
        let output_tokens: Int?
    }
    
    struct AnthropicMessageData: Codable {
        let usage: AnthropicUsage?
    }
    
    struct AnthropicStreamEvent: Codable {
        let type: String?
        let delta: AnthropicDelta?
        let message: AnthropicMessageData?
        let usage: AnthropicUsage?
    }
    
    struct AnthropicDelta: Codable {
        let type: String?
        let text: String?
    }
    
    public func sendMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String) async throws -> String {
        // Fallback for non-streaming, but we focus on streaming
        var responseText = ""
        let stream = streamMessage(messages, model: model, apiKey: apiKey, onUsageUpdate: { _ in })
        for try await event in stream {
            if case .text(let text) = event {
                responseText += text
            }
        }
        return responseText
    }
    
    public func streamMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String, onUsageUpdate: @escaping (TokenUsage) -> Void) -> AsyncThrowingStream<StreamEvent, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Extract system messages
                    let systemMessages = messages.filter { $0.role == .system }.map { $0.content }.joined(separator: "\n")
                    let systemPrompt: String? = systemMessages.isEmpty ? nil : systemMessages
                    
                    // Filter out system messages and map to Anthropic format
                    let anthropicMessages = messages.filter { $0.role != .system && $0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }.map {
                        // Anthropic doesn't use "system" in the messages array, and expects strictly alternating user/assistant if possible.
                        // For MVP, we map user/assistant roles.
                        let roleString = $0.role == .assistant ? "assistant" : "user"
                        return AnthropicMessage(role: roleString, content: $0.content)
                    }
                    
                    let requestBody = AnthropicRequest(
                        model: model.id,
                        max_tokens: 4096,
                        system: systemPrompt,
                        messages: anthropicMessages,
                        stream: true
                    )
                    
                    var request = URLRequest(url: URL(string: baseURL)!)
                    request.httpMethod = "POST"
                    request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
                    request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(requestBody)
                    
                    let (result, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        let errorData = try await result.reduce(into: Data()) { data, byte in data.append(byte) }
                        let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        throw NSError(domain: "ClaudeProvider", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
                    }
                    
                    var promptTokens = 0
                    var completionTokens = 0
                    
                    for try await line in result.lines {
                        guard line.hasPrefix("data: "), let data = line.dropFirst(6).data(using: .utf8) else { continue }
                        
                        // Ignore [DONE] or other empty lines
                        if line == "data: [DONE]" { break }
                        
                        if let event = try? JSONDecoder().decode(AnthropicStreamEvent.self, from: data) {
                            if event.type == "message_start", let usage = event.message?.usage, let input = usage.input_tokens {
                                promptTokens = input
                            } else if event.type == "message_delta", let usage = event.usage, let output = usage.output_tokens {
                                completionTokens = output
                                let tokenUsage = TokenUsage(promptTokens: promptTokens, completionTokens: completionTokens, totalTokens: promptTokens + completionTokens)
                                onUsageUpdate(tokenUsage)
                            } else if event.type == "content_block_delta", let text = event.delta?.text {
                                continuation.yield(.text(text))
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
