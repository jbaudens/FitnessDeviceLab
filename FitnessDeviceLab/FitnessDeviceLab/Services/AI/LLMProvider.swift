import Foundation

public struct AITool: Sendable {
    public let name: String
    public let description: String
    public let parameters: [String: AnyCodable] // Using AnyCodable for the JSON Schema
    
    public init(name: String, description: String, parameters: [String: AnyCodable]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

public protocol LLMProvider: Sendable {
    func sendMessage(history: [AIChatMessage], tools: [AITool]) async throws -> AIChatMessage
}
