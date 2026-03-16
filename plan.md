# Code Review: FitnessDeviceLab (Updated March 2026)

## Executive Summary
The FitnessDeviceLab codebase has undergone a significant architectural transformation. Most of the high-risk "technical debt" identified in the initial review has been addressed through a systematic refactor. The app is now highly modular, testable, and supports a robust simulation layer that allows for UI and logic testing without physical sensors.

The transition to the **Swift 6 Observation framework (@Observable)** is complete, and the separation of hardware-specific logic from business logic is well-established.

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

### Phase 3A: Singleton Elimination (DI Injection)
*   [x] **Step 3.1: Inject `SettingsManager`**: Refactor all classes to accept `SettingsManager` in their `init`.
*   [x] **Step 3.2: Inject `LocationManager`**: Refactor `WorkoutSessionManager` to receive altitude updates via a delegate or stream.
*   [x] **Step 3.3: ViewModel DI**: Update ViewModels to receive managers via initializers.

### Phase 3B: Decoupling `WorkoutSessionManager`
*   [x] **Step 3.4: Extract `TargetPowerCalculator`**: Move ERG and HR-control logic into a stateless struct. 
*   [x] **Step 3.5: [TEST] `TargetPowerCalculator`**: Add unit tests for all workout step types.
*   [x] **Step 3.6: Extract `WorkoutTimer`**: Move timer logic into a dedicated class.
*   [x] **Step 3.7: Extract `TrainerController`**: Move trainer command logic into a dedicated component.
*   [x] **Step 3.7.1: [TEST] `WorkoutSessionManager`**: Add unit tests for orchestration and transitions.

### Phase 3C: Core Logic Refinement (Centralized Math)
*   [x] **Step 3.8: Refactor `StructuredWorkout` Logic**: Move `intensityFactor` and NP logic out of the model and into `WorkoutPhysicsEngine`.
*   [x] **Step 3.9: Harmonize NP logic with `PowerMath`**: Create a shared `PowerMath` utility used by both live and static analyzers.

### Phase 3D: [COMPLETED] Environment Removal
*   [x] **Step 3.10: Settings & Library ViewModels**: Create dedicated ViewModels to remove `@Environment`.
*   [x] **Step 3.11: Component Dependency Injection**: Refactor all sub-components to take explicit dependencies.
*   [x] **Step 3.12: App Entry Point Cleanup**: Remove all `.environment(...)` calls from `FitnessDeviceLabApp`.

### Phase 3E: DataFieldEngine Redesign (Garmin Model)
*   [ ] **Step 3.13: Explicit Lap Fields**: Redefine `DataFieldType` to include explicit Lap-specific variants (e.g., `lapAvgPower`, `lapDistance`) instead of a global mode toggle.
*   [ ] **Step 3.14: Dual-Stream Calculation**: Refactor `DataFieldEngine` to calculate and expose both `sessionMetrics` and `lapMetrics` simultaneously.
*   [ ] **Step 3.15: Metric Correctness Audit**: Verify NP, TSS, and IF math against standard test cases (handling gaps and pauses).

### Phase 3F: UI & UX Refinement
*   [ ] **Step 3.16: Remove Mode Toggle**: Delete the "Session/Lap" toggle logic from the UI and Manager.
*   [ ] **Step 3.17: Update Default Profiles**: Revise `ActivityProfile` to use a mix of session and lap fields across data pages.

### Phase 3G: Workout Library Research & Design (DESIGN PHASE)
*   [ ] **Step 3.18: Format Research**: Evaluate Zwift `.zwo` (XML) vs. TrainerRoad vs. Custom JSON.
*   [ ] **Step 3.19: Storage Strategy**: Compare SwiftData vs. File-based (JSON) storage for user workouts and favorites.

### Phase 3H: Export Strategy
*   [ ] **Step 3.20: FIT Stability Confirmation**: Extensively test `FitEncoder` outputs in Garmin Connect/Strava.
*   [ ] **Step 3.21: TCX Deprecation**: Mark `TCXExporter` as legacy and eventually remove it.

### Phase 4: Verification & Integration
*   [ ] **Step 4.1: Unit Test `DataFieldEngine`**: Correctness check for all live metrics.
*   [ ] **Step 4.2: Unit Test `WorkoutPlayerViewModel`**: Verify UI actions trigger correct state changes.
*   [ ] **Step 4.3: End-to-End XCUITest**: Run a full simulated 1-minute workout and verify exports.

---

## 3. Testing Status Dashboard

| Component | Test Type | Status |
| :--- | :--- | :--- |
| `SensorDataParser` | Unit | ✅ Passed |
| `PhysicsUtilities` | Unit | ✅ Passed |
| `TargetPowerCalculator` | Unit | ✅ Passed |
| `WorkoutSessionManager` | Unit | ✅ Passed |
| `DataFieldEngine` | Unit | ❌ Missing |
| `WorkoutPlayerViewModel` | Unit | ❌ Missing |
| UI Workflows | UI (XCUITest) | ❌ Missing |

---
*Updated by Senior Engineering Consultant*
