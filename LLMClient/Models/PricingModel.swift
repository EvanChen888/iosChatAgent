import Foundation

public struct ModelPricing {
    public let inputCostPerMillion: Double
    public let outputCostPerMillion: Double
}

public struct PricingConfig {
    public static let pricing: [String: ModelPricing] = [
        "deepseek-chat": ModelPricing(inputCostPerMillion: 0.14, outputCostPerMillion: 0.28),
        "deepseek-reasoner": ModelPricing(inputCostPerMillion: 0.55, outputCostPerMillion: 2.19),
        "gpt-4o": ModelPricing(inputCostPerMillion: 5.00, outputCostPerMillion: 15.00),
        "gpt-4o-mini": ModelPricing(inputCostPerMillion: 0.15, outputCostPerMillion: 0.60),
        "claude-sonnet-4-6": ModelPricing(inputCostPerMillion: 3.00, outputCostPerMillion: 15.00),
        "claude-haiku-4-5-20251001": ModelPricing(inputCostPerMillion: 0.25, outputCostPerMillion: 1.25)
    ]
    
    public static func calculateCost(modelId: String, usage: TokenUsage) -> Double? {
        guard let price = pricing[modelId] else { return nil }
        
        let inputCost = (Double(usage.promptTokens) / 1_000_000.0) * price.inputCostPerMillion
        let outputCost = (Double(usage.completionTokens) / 1_000_000.0) * price.outputCostPerMillion
        
        return inputCost + outputCost
    }
}
