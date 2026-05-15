import Foundation

public enum AIChatRole: String, Codable, Sendable {
    case user, assistant, system, tool
}

public struct AIChatMessage: Identifiable, Codable, Sendable {
    public let id: UUID
    public let role: AIChatRole
    public let content: String
    public let toolCalls: [AIToolCall]?
    
    public init(id: UUID = UUID(), role: AIChatRole, content: String, toolCalls: [AIToolCall]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
    }
}

public struct AIToolCall: Codable, Sendable {
    public let id: String
    public let functionName: String
    public let arguments: [String: AnyCodable]
}

/// A type-safe wrapper for arbitrary JSON-compatible values.
public struct AnyCodable: Codable, Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dictionary = value as? [String: Any] {
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        } else {
            try container.encodeNil()
        }
    }
}
