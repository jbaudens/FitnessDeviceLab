import Foundation
import Observation
import SwiftUI

@Observable
public final class WorkoutAssistantCoordinator {
    public var messages: [AIChatMessage] = []
    public var isGenerating: Bool = false
    public var errorMessage: String?
    
    private let provider: LLMProvider
    private let viewModel: WorkoutEditorViewModel
    private let settings: SettingsProvider
    
    public init(viewModel: WorkoutEditorViewModel, settings: SettingsProvider, provider: LLMProvider) {
        self.viewModel = viewModel
        self.settings = settings
        self.provider = provider
        
        // Add initial system message if empty
        if messages.isEmpty {
            messages.append(AIChatMessage(role: .system, content: CoachingProfile.systemInstruction))
        }
    }
    
    @MainActor
    public func sendUserMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = AIChatMessage(role: .user, content: content)
        messages.append(userMessage)
        
        await generateAssistantResponse()
    }
    
    @MainActor
    public func clearChat() {
        messages = [AIChatMessage(role: .system, content: CoachingProfile.systemInstruction)]
    }
    
    @MainActor
    private func generateAssistantResponse() async {
        isGenerating = true
        errorMessage = nil
        
        do {
            // 1. Validate environment
            guard !KeychainHelper.readString(service: "com.fitnessdevicelab.gemini", account: "api_key").isNilOrEmpty else {
                throw AssistantError.missingApiKey
            }

            // 2. Prepare context with FRESH snapshot
            let stateSnapshot = createStateSnapshot()
            let stateMessage = AIChatMessage(role: .system, content: "CRITICAL: The current workout in the editor is EXACTLY as follows. Use this as the source of truth for all modifications: \(stateSnapshot)")
            
            // Insert the state message before the last user message to ensure the model sees the latest state 
            // before trying to act on the user's latest request.
            var history = messages
            if history.count >= 1 {
                history.insert(stateMessage, at: history.count - 1)
            } else {
                history.append(stateMessage)
            }
            
            // 3. Request generation
            let response = try await provider.sendMessage(history: history, tools: WorkoutToolRegistry.tools)
            messages.append(response)
            
            // 4. Handle tool execution
            if let toolCalls = response.toolCalls {
                for call in toolCalls {
                    try await executeToolCall(call)
                }
                
                // 5. Trigger a follow-up turn to get a verbal explanation
                // We add a hidden instruction to tell the coach to explain the changes briefly.
                let followUpInstruction = AIChatMessage(
                    role: .user, 
                    content: "The changes have been applied. Briefly confirm what you did in 1-2 sentences. Avoid being overly verbose."
                )
                
                // We don't want to show this internal instruction in the UI
                var followUpHistory = messages
                followUpHistory.append(followUpInstruction)
                
                let explanation = try await provider.sendMessage(history: followUpHistory, tools: [])
                messages.append(explanation)
            }
        } catch let error as AssistantError {
            errorMessage = error.description
        } catch {
            errorMessage = "Coach Error: \(error.localizedDescription)"
            print("Assistant execution failed: \(error)")
        }
        
        isGenerating = false
    }

    private func createStateSnapshot() -> String {
        let workout = viewModel.draftWorkout
        let snapshot: [String: Any] = [
            "workout": [
                "name": workout.name,
                "description": workout.description,
                "steps": workout.steps.enumerated().map { index, step in
                    [
                        "index": index,
                        "type": step.type.rawValue,
                        "duration": step.duration,
                        "targetPowerPercent": step.targetPowerPercent ?? 0,
                        "targetHeartRatePercent": step.targetHeartRatePercent ?? 0
                    ]
                }
            ],
            "userSettings": [
                "ftp": settings.userFTP,
                "lthr": settings.userLTHR,
                "weight": settings.userWeight
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            print("Assistant State Snapshot: \(json)")
            return json
        }
        return "{}"
    }
    
    @MainActor
    private func executeToolCall(_ call: AIToolCall) async throws {
        print("Assistant executing tool: \(call.functionName) with args: \(call.arguments.mapValues { $0.value })")
        let args = call.arguments.mapValues { $0.value }
        
        switch call.functionName {
        case "reset_workout":
            if let name = args["name"] as? String { viewModel.name = name }
            if let desc = args["description"] as? String { viewModel.description = desc }
            if let stepsData = args["steps"] as? [[String: Any]] {
                viewModel.steps = stepsData.compactMap { parseStep($0) }
            } else {
                print("Error: reset_workout missing steps or wrong format")
            }
            
        case "add_steps":
            if let stepsData = args["steps"] as? [[String: Any]] {
                let newSteps = stepsData.compactMap { parseStep($0) }
                viewModel.steps.append(contentsOf: newSteps)
            } else {
                print("Error: add_steps missing steps or wrong format")
            }
            
        case "update_steps":
            let rawIndices = args["indices"] as? [Any] ?? []
            let indices = rawIndices.compactMap { asInt($0) }
            
            if let changes = args["changes"] as? [String: Any], !indices.isEmpty {
                for index in indices {
                    guard index < viewModel.steps.count else { continue }
                    var step = viewModel.steps[index]
                    if let dur = asDouble(changes["duration"]) { step.duration = dur }
                    if let pwr = asDouble(changes["targetPowerPercent"]) { step.targetPowerPercent = pwr }
                    if let hr = asDouble(changes["targetHeartRatePercent"]) { step.targetHeartRatePercent = hr }
                    if let cad = asInt(changes["targetCadence"]) { step.targetCadence = cad }
                    if let typeStr = changes["type"] as? String, let type = WorkoutStepType(rawValue: typeStr) {
                        step.type = type
                    }
                    viewModel.steps[index] = step
                }
            } else {
                print("Error: update_steps invalid indices or changes. Indices: \(indices)")
            }
            
        case "remove_steps":
            let rawIndices = args["indices"] as? [Any] ?? []
            let indices = rawIndices.compactMap { asInt($0) }
            
            if !indices.isEmpty {
                let sortedIndices = indices.sorted(by: >)
                for index in sortedIndices {
                    if index < viewModel.steps.count {
                        viewModel.steps.remove(at: index)
                    }
                }
            } else {
                print("Error: remove_steps missing indices")
            }
            
        case "duplicate_block":
            if let start = asInt(args["start"]), 
               let end = asInt(args["end"]), 
               let repeats = asInt(args["repeats"]) {
                guard start >= 0, end < viewModel.steps.count, start <= end else { 
                    print("Error: duplicate_block indices out of range: \(start)-\(end) (count: \(viewModel.steps.count))")
                    return 
                }
                let block = Array(viewModel.steps[start...end])
                for _ in 0..<repeats {
                    let copies = block.map { original in
                        WorkoutStep(
                            duration: original.duration,
                            targetPowerPercent: original.targetPowerPercent,
                            endTargetPowerPercent: original.endTargetPowerPercent,
                            targetHeartRatePercent: original.targetHeartRatePercent,
                            type: original.type,
                            targetCadence: original.targetCadence
                        )
                    }
                    viewModel.steps.append(contentsOf: copies)
                }
            } else {
                print("Error: duplicate_block missing start/end/repeats")
            }
            
        case "set_metadata":
            if let name = args["name"] as? String { viewModel.name = name }
            if let desc = args["description"] as? String { viewModel.description = desc }
            
        default:
            print("Unknown tool call: \(call.functionName)")
        }
        
        // Add a "tool execution" message to the history for the UI to show feedback
        messages.append(AIChatMessage(role: .tool, content: "OK"))
    }
    
    private func asInt(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String { return Int(s) }
        return nil
    }
    
    private func asDouble(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let s = value as? String { return Double(s) }
        return nil
    }
    
    private func parseStep(_ dict: [String: Any]) -> WorkoutStep? {
        guard let duration = asDouble(dict["duration"]),
              let typeStr = dict["type"] as? String,
              let type = WorkoutStepType(rawValue: typeStr.capitalized) ?? WorkoutStepType(rawValue: typeStr) else {
            return nil
        }
        
        return WorkoutStep(
            duration: duration,
            targetPowerPercent: asDouble(dict["targetPowerPercent"]),
            targetHeartRatePercent: asDouble(dict["targetHeartRatePercent"]),
            type: type,
            targetCadence: asInt(dict["targetCadence"])
        )
    }

    private enum AssistantError: Error {
        case missingApiKey
        
        var description: String {
            switch self {
            case .missingApiKey: return "API Key missing. Please tap the key icon at the top to setup your Gemini API key."
            }
        }
    }
}

public struct CoachingProfile {
    public static let systemInstruction = """
    You are an expert Cycling Coach assistant for "Fitness Device Lab". 
    Your goal is to help users design and refine structured indoor cycling workouts.
    
    CORE PRINCIPLES:
    1. Physiology First: Understand Power Zones (Coggan 1-7) and HR Zones. 
    2. Structured Sets: Warmups should be progressive. Work sets should have clear recovery ratios.
    3. Conversational: Be encouraging, professional, and concise. 
    4. Proactive: If a user asks for "Threshold", suggest a classic 4x10min or Over-Unders.
    5. Adaptive: Ask about their goals or fatigue level if a request is vague.
    
    TOOL USAGE:
    - You have tools to reset, add, update, remove, and duplicate steps.
    - When you call a tool, also provide a brief textual explanation of what you've done.
    - Always output intensities as decimals (e.g. 0.95 for 95% FTP).
    
    FORMATTING:
    - Never mention JSON or internal IDs to the user.
    - Focus on the coaching benefit of the workout structure.
    """
}

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
