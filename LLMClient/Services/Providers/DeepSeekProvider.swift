import Foundation

public class DeepSeekProvider: OpenAIProvider {
    
    public init() {
        super.init(
            endpointUrl: URL(string: "https://api.deepseek.com/chat/completions")!,
            providerId: .deepseek
        )
    }
}
