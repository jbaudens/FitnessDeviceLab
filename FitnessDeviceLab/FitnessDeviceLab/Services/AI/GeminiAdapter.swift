import Foundation
import GoogleGenerativeAI

/// An adapter for the Google Gemini API that conforms to `LLMProvider`.
public final class GeminiAdapter: LLMProvider, @unchecked Sendable {
    private let modelName: String
    private let apiKey: String
    
    /// Initializes a new Gemini adapter.
    /// - Parameters:
    ///   - apiKey: The Google AI API key.
    ///   - modelName: The model to use (default is "gemini-1.5-flash").
    public init(apiKey: String, modelName: String = "gemini-1.5-flash") {
        self.apiKey = apiKey
        self.modelName = modelName
    }
    
    public func sendMessage(history: [AIChatMessage], tools: [AITool]) async throws -> AIChatMessage {
        let generativeTools = tools.isEmpty ? nil : [Tool(functionDeclarations: tools.compactMap { $0.toFunctionDeclaration() })]
        
        // Extract system instructions. Gemini 1.5 prefers them separately.
        let systemMessages = history.filter { $0.role == .system }
        var systemInstruction: ModelContent? = nil
        if !systemMessages.isEmpty {
            let systemParts = systemMessages.map { ModelContent.Part.text($0.content) }
            systemInstruction = try? ModelContent(role: "system", systemParts)
        }
        
        let model = GenerativeModel(
            name: modelName,
            apiKey: apiKey,
            tools: generativeTools,
            systemInstruction: systemInstruction
        )
        
        // Map history to Gemini content, excluding system messages already handled.
        let contents = mapHistory(history)
        
        let response = try await model.generateContent(contents)
        
        return try response.toAIChatMessage()
    }
    
    private func mapHistory(_ history: [AIChatMessage]) -> [ModelContent] {
        var contents: [ModelContent] = []
        
        for (index, message) in history.enumerated() {
            if message.role == .system { continue }
            
            if message.role == .tool {
                let functionName = findFunctionName(forToolMessageAt: index, in: history)
                let jsonResponse: JSONObject = parseToolContent(message.content)
                
                let responsePart = ModelContent.Part.functionResponse(FunctionResponse(name: functionName, response: jsonResponse))
                if let toolContent = try? ModelContent(role: "function", [responsePart]) {
                    contents.append(toolContent)
                }
            } else {
                let modelRole = message.role == .user ? "user" : "model"
                var messageParts: [ModelContent.Part] = []
                
                if !message.content.isEmpty {
                    messageParts.append(.text(message.content))
                }
                
                if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    for call in toolCalls {
                        let args = call.arguments.mapValues { $0.toJSONValue() }
                        messageParts.append(.functionCall(FunctionCall(name: call.functionName, args: args)))
                    }
                }
                
                if !messageParts.isEmpty {
                    if let mc = try? ModelContent(role: modelRole, messageParts) {
                        contents.append(mc)
                    }
                }
            }
        }
        
        return contents
    }
    
    private func findFunctionName(forToolMessageAt index: Int, in history: [AIChatMessage]) -> String {
        var toolMessageCount = 0
        for i in (0..<index).reversed() {
            if history[i].role == .tool {
                toolMessageCount += 1
            } else if history[i].role == .assistant, let calls = history[i].toolCalls {
                if toolMessageCount < calls.count {
                    return calls[toolMessageCount].functionName
                }
                toolMessageCount -= calls.count
            }
        }
        return "unknown_function"
    }
    
    private func parseToolContent(_ content: String) -> JSONObject {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ["result": .string(content)]
        }
        return json.mapValues { JSONValue.fromAny($0) }
    }
}

// MARK: - Mapping Helpers

extension AITool {
    func toFunctionDeclaration() -> FunctionDeclaration {
        let schemaDict = parameters.mapValues { $0.value } as [String: Any]
        let properties = (schemaDict["properties"] as? [String: Any])?.compactMapValues { Schema.map($0) }
        let required = schemaDict["required"] as? [String]
        
        return FunctionDeclaration(
            name: name,
            description: description,
            parameters: properties,
            requiredParameters: required
        )
    }
}

extension Schema {
    static func map(_ value: Any?) -> Schema? {
        guard let dict = value as? [String: Any] else { return nil }
        
        let typeString = (dict["type"] as? String)?.uppercased() ?? "OBJECT"
        let type: DataType = DataType(rawValue: typeString) ?? .object
        
        return Schema(
            type: type,
            format: dict["format"] as? String,
            description: dict["description"] as? String,
            nullable: dict["nullable"] as? Bool,
            enumValues: dict["enum"] as? [String],
            items: map(dict["items"] ?? dict["item"]),
            properties: (dict["properties"] as? [String: Any])?.compactMapValues { map($0) },
            requiredProperties: dict["required"] as? [String]
        )
    }
}

extension GenerateContentResponse {
    func toAIChatMessage() throws -> AIChatMessage {
        let content = text ?? ""
        var toolCalls: [AIToolCall] = []
        
        if let candidate = candidates.first {
            for part in candidate.content.parts {
                if case let .functionCall(call) = part {
                    toolCalls.append(AIToolCall(
                        id: UUID().uuidString,
                        functionName: call.name,
                        arguments: call.args.mapValues { AnyCodable($0.toAny()) }
                    ))
                }
            }
        }
        
        return AIChatMessage(
            role: .assistant,
            content: content,
            toolCalls: toolCalls.isEmpty ? nil : toolCalls
        )
    }
}

extension AnyCodable {
    func toJSONValue() -> JSONValue {
        return JSONValue.fromAny(value)
    }
}

extension JSONValue {
    static func fromAny(_ value: Any) -> JSONValue {
        if let s = value as? String { return .string(s) }
        if let n = value as? Double { return .number(n) }
        if let i = value as? Int { return .number(Double(i)) }
        if let b = value as? Bool { return .bool(b) }
        if let a = value as? [Any] { return .array(a.map { fromAny($0) }) }
        if let d = value as? [String: Any] { return .object(d.mapValues { fromAny($0) }) }
        return .null
    }
    
    func toAny() -> Any {
        switch self {
        case .string(let s): return s
        case .number(let n): return n
        case .bool(let b): return b
        case .array(let a): return a.map { $0.toAny() }
        case .object(let o): return o.mapValues { $0.toAny() }
        case .null: return NSNull()
        }
    }
}
