# Design Spec: AI Workout Assistant

**Status:** Draft | **Date:** 2026-05-12  
**Feature Branch:** `feature/ai-workout-assistant`

## 1. Goal & Vision
Implement an AI-powered "Cycling Coach" assistant directly within the Workout Editor. Users can create, modify, and discuss workouts using natural language. The assistant should possess deep knowledge of cycling physiology (FTP, LTHR, Coggan/Friel zones) and provide structured workouts that can be directly applied to the editor.

## 2. Architecture

### 2.1 Double-Abstraction Layer
To ensure future-proofing and vendor-neutrality (allowing for easy switching from Google Gemini to local LLMs like MLX/Llama.cpp), we use a two-tier abstraction:

- **`LLMProvider` (Protocol)**: The high-level interface used by the app.
  - `func sendMessage(history: [ChatMessage], tools: [WorkoutTool]) async throws -> LLMResponse`
- **Adapters**: Concrete implementations for specific backends.
  - `GeminiAdapter`: Translates `WorkoutTool` into Gemini-native `FunctionDeclaration`.
  - `LocalLLMAdapter` (Future): Translates `WorkoutTool` into JSON instructions injected into the system prompt.

### 2.2 Component Responsibilities
- **`WorkoutAssistantCoordinator`**: Manages the chat session, persists history, and executes tool calls returned by the AI. It observes `WorkoutEditorViewModel` to keep the AI's context in sync with manual user edits.
- **`WorkoutToolRegistry`**: Defines the JSON schema for all actions the AI can perform (e.g., `add_steps`, `duplicate_block`).
- **`CoachingProfile`**: A curated system prompt defining the AI's persona, coaching philosophy, and knowledge of the app's internal workout models.

## 3. Toolset (AI Actions)

| Tool Name | Parameters | Description |
| :--- | :--- | :--- |
| `reset_workout` | `name`, `description`, `steps` | Starts a fresh workout design. |
| `add_steps` | `[WorkoutStep]` | Appends new steps to the workout. |
| `update_steps` | `indices: [Int]`, `changes: StepUpdate` | Modifies existing steps by index. |
| `remove_steps` | `indices: [Int]` | Deletes steps by index. |
| `duplicate_block` | `start: Int, end: Int, repeats: Int` | Repeats a range of steps (intervals). |
| `set_metadata` | `name: String?, description: String?` | Updates workout title or notes. |

## 4. User Interface

### 4.1 The Sidebar (Mac/iPad) / Drawer (iPhone)
- **Placement**: Right-side collapsible panel (Mac/iPad) or bottom sheet (iPhone).
- **Chat Feed**: Standard message bubbles.
- **Context Badge**: An indicator showing that the AI "knows" the current user's FTP/LTHR and current workout state.
- **Action Feedback**: When a tool is executed, a system message appears (e.g., *"Coach added 3 intervals"*).

### 4.2 API Key Management
- Users provide their own **Gemini API Key**.
- Key is stored in the **System Keychain**.
- The app uses **Gemini 1.5 Flash** for its free-tier speed and function-calling capabilities.

## 5. Verification & Testing
- **`MockLLMProvider`**: For UI and state-machine testing without hitting the network.
- **Schema Validation**: Unit tests to ensure `LLMResponse` tool calls map correctly to `WorkoutStep` objects.
- **Golden Prompt Suite**: A collection of reference prompts to verify the "Coach" persona and workout quality during manual QA.

## 6. Privacy
- No PII (names, emails, locations) sent to the LLM.
- Only technical data (FTP, LTHR, current workout steps) is included in the context.
