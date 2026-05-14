import Foundation
import GoogleGenerativeAI

/// An adapter for the Google Gemini API that conforms to `LLMProvider`.
public final class GeminiAdapter: LLMProvider, @unchecked Sendable {
    private let modelName: String
    private let apiKey: String
    
    /// Initializes a new Gemini adapter.
    /// - Parameters:
    ///   - apiKey: The Google AI API key.
    ///   - modelName: The model to use (default is "gemini-2.5-flash").
    public init(apiKey: String, modelName: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.modelName = modelName
    }
    
    public func sendMessage(history: [AIChatMessage], tools: [AITool]) async throws -> AIChatMessage {
        let generativeTools = tools.isEmpty ? nil : [GoogleGenerativeAI.Tool(functionDeclarations: tools.compactMap { $0.toFunctionDeclaration() })]
        
        // Extract system instructions. Gemini 1.5 prefers them separately.
        let systemMessages = history.filter { $0.role == .system }
        var systemInstruction: ModelContent? = nil
        if !systemMessages.isEmpty {
            let systemText = systemMessages.map { $0.content }.joined(separator: "\n")
            // Note: The role for systemInstruction should typically be nil in the Swift SDK
            systemInstruction = ModelContent(parts: [.text(systemText)])
        }
        
        let model = GenerativeModel(
            name: modelName,
            apiKey: apiKey,
            tools: generativeTools,
            systemInstruction: systemInstruction
        )
        
        let contents = mapHistory(history)
        
        print("Sending request to Gemini model: \(modelName)")
        print("- Contents count: \(contents.count)")
        print("- Tools provided: \(generativeTools != nil)")
        
        do {
            let response = try await model.generateContent(contents)
            return try response.toAIChatMessage()
        } catch {
            throw mapError(error)
        }
    }
    
    private func mapError(_ error: Error) -> Error {
        if let genError = error as? GenerateContentError {
            switch genError {
            case .internalError(let underlying):
                let detail = String(describing: underlying)
                print("Gemini Internal Error detected: \(underlying.localizedDescription)\nDetails: \(detail)")
                
                let userMessage = "Gemini encountered an internal error. This often happens if the service is overloaded or if there's a configuration issue."
                return AssistantDisplayError("\(userMessage)\n\(detail)")
                
            case .promptBlocked(let response):
                let reason = response.promptFeedback?.blockReason?.rawValue ?? "Unknown"
                return AssistantDisplayError("Prompt Blocked: The request was blocked by safety filters (Reason: \(reason)).")
            case .responseStoppedEarly(let reason, _):
                return AssistantDisplayError("Response Stopped: The AI stopped generating early (Reason: \(reason.rawValue)).")
            case .invalidAPIKey(let message):
                return AssistantDisplayError("Invalid API Key: \(message)")
            case .unsupportedUserLocation:
                return AssistantDisplayError("Unsupported Region: Gemini API is not yet available in your current location/region.")
            default:
                return AssistantDisplayError("Gemini Error: \(error.localizedDescription)")
            }
        }
        return error
    }
    
    private func mapHistory(_ history: [AIChatMessage]) -> [ModelContent] {
        return history.compactMap { (message: AIChatMessage) -> ModelContent? in
            if message.role == .system { return nil }
            
            if message.role == .tool {
                let functionName = findFunctionName(forToolMessage: message, in: history)
                let jsonResponse: JSONObject = parseToolContent(message.content)
                
                let part = ModelContent.Part.functionResponse(FunctionResponse(name: functionName, response: jsonResponse))
                return ModelContent(role: "function", parts: [part])
            } else {
                let role = message.role == .user ? "user" : "model"
                var parts: [ModelContent.Part] = []
                
                if !message.content.isEmpty {
                    parts.append(.text(message.content))
                }
                
                if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    for call in toolCalls {
                        let args = call.arguments.mapValues { $0.value }
                        let json: [String: Any] = ["name": call.functionName, "args": args]
                        if let data = try? JSONSerialization.data(withJSONObject: json),
                           let functionCall = try? JSONDecoder().decode(FunctionCall.self, from: data) {
                            parts.append(.functionCall(functionCall))
                        } else {
                            print("Warning: Failed to decode FunctionCall for \(call.functionName)")
                        }
                    }
                }
                
                guard !parts.isEmpty else { return nil }
                return ModelContent(role: role, parts: parts)
            }
        }
    }
    
    private func findFunctionName(forToolMessage message: AIChatMessage, in history: [AIChatMessage]) -> String {
        // Find the index of the tool message
        guard let index = history.firstIndex(where: { $0.id == message.id }) else { return "unknown_function" }
        
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

struct AssistantDisplayError: Error, LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
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
