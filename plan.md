# Code Review: FitnessDeviceLab (Updated March 2026)

## Executive Summary
The FitnessDeviceLab codebase has undergone a significant architectural transformation. Most of the high-risk "technical debt" identified in the initial review has been addressed through a systematic refactor. The app is now highly modular, testable, and supports a robust simulation layer that allows for UI and logic testing without physical sensors.

The transition to the **Swift 6 Observation framework (`@Observable`)** is nearly complete, and the separation of hardware-specific logic from business logic is well-established.

---

## 1. Architectural Progress & Achievements

### A. Modular Structure
*   **Status:** **Completed**.
*   **Change:** organized into logical domains: `Core`, `Engines`, `Services`, `Features`, and `UI`.

### B. Hardware Decoupling (Protocol-Oriented)
*   **Status:** **Completed**.
*   **Change:** Bluetooth interactions now happen through the `SensorPeripheral` and `BluetoothDriver` protocols.

### C. Simulation Layer ("Virtual Bike")
*   **Status:** **Implemented**.
*   **Change:** `SimulatedPeripheral` provides realistic, physics-based data with physiological drift and ERG-mode response.

### D. Modern State Management
*   **Status:** **Completed**.
*   **Change:** Migration from `ObservableObject` to `@Observable`.

### E. Logic Extraction
*   **Status:** **Completed**.
*   **Change:** Extracted `SensorDataParser`, `DataFieldEngine`, and `PhysicsUtilities` into pure-logic components.

---

## 2. Refined Refactor Plan: Small, Reviewable Steps

To ensure high-quality code reviews and maintain stability, the remaining refactor is broken down into atomic tasks.

### Phase 3A: Singleton Elimination (DI Injection)
*   [x] **Step 3.1: Inject `SettingsManager`**: Refactor all classes to accept `SettingsManager` in their `init`. Remove global `.shared` usage in `DataFieldEngine` and `WorkoutSessionManager`.
*   [x] **Step 3.2: Inject `LocationManager`**: Refactor `WorkoutSessionManager` to receive altitude updates via a delegate or stream instead of polling `LocationManager.shared`.
*   [x] **Step 3.3: ViewModel DI**: Update `WorkoutPlayerViewModel` and `DevicesViewModel` to receive their managers via initializers in the App entry point, removing the reliance on `@Environment` for core business logic.

### Phase 3B: Decoupling `WorkoutSessionManager`
*   [x] **Step 3.4: Extract `TargetPowerCalculator`**: Move the complex ERG and HR-control logic (found in `tick()`) into a pure, stateless struct. 
*   [ ] **Step 3.5: [TEST] `TargetPowerCalculator`**: Add unit tests for all workout step types (Power, %FTP, %HR) and difficulty scaling.
*   [ ] **Step 3.6: Extract `WorkoutTimer`**: Move the `Timer.publish` logic into a dedicated class to allow for easier testing of "time-skipped" workouts in the future.
*   [ ] **Step 3.7: Extract `TrainerController`**: Move the logic that commands the `controlSource` (trainer) into a dedicated component.

### Phase 3C: Export & Persistence Improvements
*   [ ] **Step 3.8: Structured TCX Export**: Replace manual string concatenation in `SessionRecorder` with a proper XML builder or Codable-based approach.
*   [ ] **Step 3.9: SwiftData Integration**: (Optional) Transition the `WorkoutLibrary` from static files to a SwiftData store for better persistence and user customization.

### Phase 3D: Complete Environment Removal
*   [ ] **Step 3.10: Settings & Library ViewModels**: Create dedicated ViewModels for `SettingsView` and `WorkoutLibraryView` to remove their reliance on `@Environment`.
*   [ ] **Step 3.11: Component Dependency Injection**: Refactor sub-components (like `WorkoutGraphView`, `WorkoutTargetHeader`, `LapsHistoryView`) to take dependencies via initializers instead of `@Environment`.
*   [ ] **Step 3.12: App Entry Point Cleanup**: Remove all `.environment(...)` calls from `FitnessDeviceLabApp` to ensure a strictly explicit dependency graph.

### Phase 4: Verification & Integration
*   [ ] **Step 4.1: Unit Test `DataFieldEngine`**: Ensure all calculated metrics (NP, TSS, IF) are correct against a known set of power samples.
*   [ ] **Step 4.2: Unit Test `WorkoutPlayerViewModel`**: Use the simulation layer to verify that UI actions (Pause, Lap, Stop) trigger the correct manager states.
*   [ ] **Step 4.3: End-to-End XCUITest**: Create a "Full Workout" UI test that runs a 1-minute simulated workout and verifies the export files are generated.

---

## 3. Testing Status Dashboard

| Component | Test Type | Status |
| :--- | :--- | :--- |
| `SensorDataParser` | Unit | ✅ Passed |
| `PhysicsUtilities` | Unit | ✅ Passed |
| `TargetPowerCalculator` | Unit | 📅 Planned (Step 3.5) |
| `DataFieldEngine` | Unit | ❌ Missing |
| `WorkoutPlayerViewModel` | Unit | ❌ Missing |
| UI Workflows | UI (XCUITest) | ❌ Missing |

---
*Updated by Senior Engineering Consultant*
