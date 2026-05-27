import Foundation

struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String
}

struct GeminiPart: Codable {
    let text: String?
    let inlineData: GeminiInlineData?
    
    init(text: String? = nil, inlineData: GeminiInlineData? = nil) {
        self.text = text
        self.inlineData = inlineData
    }
}

struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

struct GeminiSystemInstruction: Codable {
    let parts: [GeminiPart]
}

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let systemInstruction: GeminiSystemInstruction?
}

struct GeminiStreamResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            let parts: [GeminiPart]?
        }
        let content: Content?
    }
    struct UsageMetadata: Codable {
        let promptTokenCount: Int?
        let candidatesTokenCount: Int?
        let totalTokenCount: Int?
    }
    
    let candidates: [Candidate]?
    let usageMetadata: UsageMetadata?
}

public class GeminiProvider: LLMProvider {
    public let providerId: AIProvider = .gemini
    
    public init() {}
    
    public func sendMessage(_ messages: [ChatMessage], model: AIModel, apiKey: String) async throws -> String {
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
                    let systemMessages = messages.filter { $0.role == .system }.map { $0.content }.joined(separator: "\n")
                    let systemInstruction: GeminiSystemInstruction? = systemMessages.isEmpty ? nil : GeminiSystemInstruction(parts: [GeminiPart(text: systemMessages)])
                    
                    let contents = messages.filter { $0.role != .system }.map { msg -> GeminiContent in
                        let role = msg.role == .user ? "user" : "model"
                        var parts: [GeminiPart] = []
                        if let attachments = msg.attachments, !attachments.isEmpty {
                            for attachment in attachments {
                                if attachment.type == .image, let data = attachment.data {
                                    let base64 = data.base64EncodedString()
                                    parts.append(GeminiPart(inlineData: GeminiInlineData(mimeType: "image/jpeg", data: base64)))
                                } else if attachment.type == .text {
                                    var textContent: String? = nil
                                    if let data = attachment.data {
                                        textContent = String(data: data, encoding: .utf8)
                                    } else if let url = attachment.url {
                                        textContent = try? String(contentsOf: url)
                                    }
                                    if let text = textContent {
                                        parts.append(GeminiPart(text: "\n--- File: \(attachment.fileName ?? "") ---\n\(text)"))
                                    }
                                }
                            }
                        }
                        parts.append(GeminiPart(text: msg.content))
                        return GeminiContent(role: role, parts: parts)
                    }
                    
                    let requestBody = GeminiRequest(contents: contents, systemInstruction: systemInstruction)
                    
                    let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model.id):streamGenerateContent?alt=sse&key=\(apiKey)"
                    guard let url = URL(string: urlString) else {
                        throw URLError(.badURL)
                    }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONEncoder().encode(requestBody)
                    
                    let (result, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        let errorData = try await result.reduce(into: Data()) { data, byte in data.append(byte) }
                        let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        throw NSError(domain: "GeminiProvider", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
                    }
                    
                    for try await line in result.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonStr = line.dropFirst(6)
                        if jsonStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
                        
                        guard let data = jsonStr.data(using: .utf8) else { continue }
                        
                        do {
                            let chunk = try JSONDecoder().decode(GeminiStreamResponse.self, from: data)
                            if let text = chunk.candidates?.first?.content?.parts?.first?.text {
                                continuation.yield(.text(text))
                            }
                            if let usage = chunk.usageMetadata {
                                let prompt = usage.promptTokenCount ?? 0
                                let completion = usage.candidatesTokenCount ?? 0
                                let total = usage.totalTokenCount ?? (prompt + completion)
                                let tokenUsage = TokenUsage(promptTokens: prompt, completionTokens: completion, totalTokens: total)
                                onUsageUpdate(tokenUsage)
                            }
                        } catch {
                            continue
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
