# AI Workout Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an AI-powered "Cycling Coach" assistant directly within the Workout Editor using Gemini 1.5 Flash.

**Architecture:** Use a `LLMProvider` protocol with a `GeminiAdapter` implementation. A `WorkoutAssistantCoordinator` will bridge the chat UI with the `WorkoutEditorViewModel` via a tool registry (Function Calling).

**Tech Stack:** Swift, SwiftUI, Gemini API (Google Generative AI SDK), Observation framework.

---

### Task 1: Core Models & Abstraction Layer

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/Services/AI/AIModels.swift`
- Create: `FitnessDeviceLab/FitnessDeviceLab/Services/AI/LLMProvider.swift`

- [ ] **Step 1: Define AI Models (Message, Tool, Response)**

```swift
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

public struct AnyCodable: Codable, Sendable {
    public let value: Any
    public init(_ value: Any) { self.value = value }
    public init(from decoder: Decoder) throws { fatalError("Not implemented") }
    public func encode(to encoder: Encoder) throws { /* Encoding logic */ }
}
```

- [ ] **Step 2: Define LLMProvider Protocol**

```swift
public protocol LLMProvider: Sendable {
    func sendMessage(history: [AIChatMessage], tools: [AITool]) async throws -> AIChatMessage
}

public struct AITool: Sendable {
    public let name: String
    public let description: String
    public let parameters: [String: Any] // JSON Schema
}
```

- [ ] **Step 3: Commit**

```bash
git add FitnessDeviceLab/FitnessDeviceLab/Services/AI/*.swift
git commit -m "feat: add AI models and LLMProvider abstraction"
```

### Task 2: Workout Tool Registry

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/Services/AI/WorkoutToolRegistry.swift`

- [ ] **Step 1: Define Workout Tools and Schemas**

```swift
import Foundation

public struct WorkoutToolRegistry {
    public static let tools: [AITool] = [
        AITool(
            name: "add_steps",
            description: "Adds one or more workout steps to the end of the current workout.",
            parameters: [
                "type": "object",
                "properties": [
                    "steps": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "properties": [
                                "duration": ["type": "number", "description": "Duration in seconds"],
                                "targetPowerPercent": ["type": "number", "description": "Intensity as % of FTP (0.0 to 2.0)"],
                                "type": ["type": "string", "enum": ["warmup", "work", "recovery", "cooldown"]]
                            ],
                            "required": ["duration", "type"]
                        ]
                    ]
                ],
                "required": ["steps"]
            ]
        )
        // More tools to be added here
    ]
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat: define workout tool registry"
```

### Task 3: Gemini Adapter Implementation

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/Services/AI/GeminiAdapter.swift`

- [ ] **Step 1: Implement GeminiAdapter using Google Generative AI SDK**

```swift
import Foundation
import GoogleGenerativeAI

public struct GeminiAdapter: LLMProvider {
    private let model: GenerativeModel
    
    public init(apiKey: String) {
        self.model = GenerativeModel(name: "gemini-1.5-flash", apiKey: apiKey)
    }
    
    public func sendMessage(history: [AIChatMessage], tools: [AITool]) async throws -> AIChatMessage {
        // Implementation: Map history to [ModelContent], map tools to [FunctionDeclaration]
        // Call model.generateContent()
        // Map response back to AIChatMessage
    }
}
```

- [ ] **Step 2: Commit**

```bash
git commit -m "feat: implement GeminiAdapter"
```

### Task 4: Workout Assistant Coordinator

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/Services/AI/WorkoutAssistantCoordinator.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutEditorViewModel.swift`

- [ ] **Step 1: Implement Coordinator to manage state and tool execution**
- [ ] **Step 2: Integrate Coordinator into WorkoutEditorViewModel**
- [ ] **Step 3: Commit**

```bash
git commit -m "feat: add assistant coordinator and integrate into view model"
```

### Task 5: AI Assistant Sidebar UI

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/AssistantSidebarView.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutEditorView.swift`

- [ ] **Step 1: Create chat message bubbles and input field**
- [ ] **Step 2: Add collapsible sidebar to WorkoutEditorView**
- [ ] **Step 3: Build and verify on macOS/iOS**
- [ ] **Step 4: Commit**

```bash
git commit -m "feat: implement assistant sidebar UI"
```
