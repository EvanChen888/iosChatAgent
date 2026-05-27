import Foundation

public enum OpenAIMessageContent: Codable {
    case text(String)
    case array([OpenAIContentPart])
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        }
    }
}

public struct OpenAIContentPart: Codable {
    public let type: String
    public let text: String?
    public let image_url: OpenAIImageUrl?
    
    public init(type: String, text: String? = nil, image_url: OpenAIImageUrl? = nil) {
        self.type = type
        self.text = text
        self.image_url = image_url
    }
}

public struct OpenAIImageUrl: Codable {
    public let url: String
}

public struct OpenAIRequestMessage: Codable {
    public let role: String
    public let content: OpenAIMessageContent
}

public struct OpenAIStreamOptions: Codable {
    public let include_usage: Bool
}

public struct OpenAIRequest: Codable {
    public let model: String
    public let messages: [OpenAIRequestMessage]
    public let stream: Bool
    public let stream_options: OpenAIStreamOptions?
}

public struct OpenAIStreamResponse: Codable {
    public struct Choice: Codable {
        public struct Delta: Codable {
            public let content: String?
            public let reasoning_content: String?
        }
        public let delta: Delta
    }
    public struct Usage: Codable {
        public let prompt_tokens: Int
        public let completion_tokens: Int
        public let total_tokens: Int
    }
    public let choices: [Choice]?
    public let usage: Usage?
}

public class OpenAIProvider: LLMProvider {
    public let providerId: AIProvider
    public let endpointUrl: URL
    
    public init(endpointUrl: URL = URL(string: "https://api.openai.com/v1/chat/completions")!, providerId: AIProvider = .openai) {
        self.endpointUrl = endpointUrl
        self.providerId = providerId
    }
    
    private func buildRequest(messages: [ChatMessage], model: AIModel, apiKey: String, stream: Bool) throws -> URLRequest {
        var request = URLRequest(url: endpointUrl)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let apiMessages = messages.map { msg -> OpenAIRequestMessage in
            if let attachments = msg.attachments, !attachments.isEmpty {
                var parts: [OpenAIContentPart] = []
                parts.append(OpenAIContentPart(type: "text", text: msg.content))
                
                for attachment in attachments {
                    if attachment.type == .image, let data = attachment.data {
                        let base64 = data.base64EncodedString()
                        let url = "data:image/jpeg;base64,\(base64)"
                        parts.append(OpenAIContentPart(type: "image_url", image_url: OpenAIImageUrl(url: url)))
                    } else if attachment.type == .pdf, let url = attachment.url {
                        // Handled in view model
                    } else if attachment.type == .text {
                        var textContent: String? = nil
                        if let data = attachment.data {
                            textContent = String(data: data, encoding: .utf8)
                        } else if let url = attachment.url {
                            textContent = try? String(contentsOf: url)
                        }
                        if let text = textContent {
                            parts.append(OpenAIContentPart(type: "text", text: "\n--- File: \(attachment.fileName ?? "") ---\n\(text)"))
                        }
                    }
                }
                return OpenAIRequestMessage(role: msg.role.rawValue, content: .array(parts))
            } else {
                return OpenAIRequestMessage(role: msg.role.rawValue, content: .text(msg.content))
            }
        }
        let streamOptions = stream ? OpenAIStreamOptions(include_usage: true) : nil
        let body = OpenAIRequest(model: model.id, messages: apiMessages, stream: stream, stream_options: streamOptions)
        request.httpBody = try JSONEncoder().encode(body)
        
        return request
    }
    
    public func sendMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String) async throws -> String {
        let request = try buildRequest(messages: messages, model: model, apiKey: apiKey, stream: false)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Non-streaming response parsing
        struct OpenAINonStreamResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String?
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let result = try JSONDecoder().decode(OpenAINonStreamResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
    
    public func streamMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String, onUsageUpdate: @escaping (TokenUsage) -> Void) -> AsyncThrowingStream<StreamEvent, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(messages: messages, model: model, apiKey: apiKey, stream: true)
                    let (result, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        // Error handling
                        let errorData = try await result.reduce(into: Data()) { $0.append($1) }
                        let errorStr = String(data: errorData, encoding: .utf8) ?? "Unknown Error"
                        continuation.finish(throwing: NSError(domain: "OpenAIError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: errorStr]))
                        return
                    }
                    
                    for try await line in result.lines {
                        if line.hasPrefix("data: ") {
                            let jsonStr = line.dropFirst(6)
                            if jsonStr == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            
                            guard let data = jsonStr.data(using: .utf8) else { continue }
                            do {
                                let chunk = try JSONDecoder().decode(OpenAIStreamResponse.self, from: data)
                                if let delta = chunk.choices?.first?.delta {
                                    if let reasoning = delta.reasoning_content, !reasoning.isEmpty {
                                        continuation.yield(.reasoning(reasoning))
                                    }
                                    if let text = delta.content, !text.isEmpty {
                                        continuation.yield(.text(text))
                                    }
                                }
                                if let usage = chunk.usage {
                                    let tokenUsage = TokenUsage(
                                        promptTokens: usage.prompt_tokens,
                                        completionTokens: usage.completion_tokens,
                                        totalTokens: usage.total_tokens
                                    )
                                    onUsageUpdate(tokenUsage)
                                }
                            } catch {
                                // Ignore parsing errors for empty chunks or incomplete JSON
                                continue
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
