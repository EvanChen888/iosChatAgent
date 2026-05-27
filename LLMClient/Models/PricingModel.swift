import Foundation

public struct ModelPricing {
    public let inputCostPerMillion: Double
    public let outputCostPerMillion: Double
}

public struct PricingConfig {
    public static let pricing: [String: ModelPricing] = [
        "deepseek-v4-pro": ModelPricing(inputCostPerMillion: 1.00, outputCostPerMillion: 3.00),
        "deepseek-v4-flash": ModelPricing(inputCostPerMillion: 0.10, outputCostPerMillion: 0.20),
        "gpt-5.5": ModelPricing(inputCostPerMillion: 5.00, outputCostPerMillion: 15.00),
        "gpt-5.4-mini": ModelPricing(inputCostPerMillion: 0.15, outputCostPerMillion: 0.60),
        "claude-opus-4-7": ModelPricing(inputCostPerMillion: 15.00, outputCostPerMillion: 75.00),
        "claude-sonnet-4-6": ModelPricing(inputCostPerMillion: 3.00, outputCostPerMillion: 15.00),
        "claude-haiku-4-5": ModelPricing(inputCostPerMillion: 0.25, outputCostPerMillion: 1.25),
        "gemini-3.5-flash": ModelPricing(inputCostPerMillion: 0.075, outputCostPerMillion: 0.30),
        "gemini-3.1-pro-preview": ModelPricing(inputCostPerMillion: 3.50, outputCostPerMillion: 10.50)
    ]
    
    public static func calculateCost(modelId: String, usage: TokenUsage) -> Double? {
        guard let price = pricing[modelId] else { return nil }
        
        let inputCost = (Double(usage.promptTokens) / 1_000_000.0) * price.inputCostPerMillion
        let outputCost = (Double(usage.completionTokens) / 1_000_000.0) * price.outputCostPerMillion
        
        return inputCost + outputCost
    }
}
