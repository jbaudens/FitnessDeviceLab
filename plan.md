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
*   [x] **Step 3.1: Inject `SettingsManager`**: Refactor all classes to accept `SettingsManager` in their `init`. Remove global `.shared` usage in `DataFieldEngine` and `WorkoutSessionManager`.
*   [x] **Step 3.2: Inject `LocationManager`**: Refactor `WorkoutSessionManager` to receive altitude updates via a delegate or stream instead of polling `LocationManager.shared`.
*   [x] **Step 3.3: ViewModel DI**: Update `WorkoutPlayerViewModel` and `DevicesViewModel` to receive their managers via initializers in the App entry point, removing the reliance on `@Environment` for core business logic.

### Phase 3B: Decoupling `WorkoutSessionManager`
*   [x] **Step 3.4: Extract `TargetPowerCalculator`**: Move the complex ERG and HR-control logic (found in `tick()`) into a pure, stateless struct. 
*   [x] **Step 3.5: [TEST] `TargetPowerCalculator`**: Add unit tests for all workout step types (Power, %FTP, %HR) and difficulty scaling.
*   [x] **Step 3.6: Extract `WorkoutTimer`**: Move the `Timer.publish` logic into a dedicated class to allow for easier testing of "time-skipped" workouts in the future.
*   [x] **Step 3.7: Extract `TrainerController`**: Move the logic that commands the `controlSource` (trainer) into a dedicated component.
*   [x] **Step 3.7.1: [TEST] `WorkoutSessionManager`**: Add unit tests for workout orchestration, step transitions, and timer-based state changes using the decoupled `WorkoutTimer`.

### Phase 3C: Core Logic Refinement (High Priority)
*   [ ] **Step 3.8: Refactor `StructuredWorkout` Logic**: Move `intensityFactor` and NP calculation logic out of the `StructuredWorkout` struct and into a dedicated `WorkoutPhysicsEngine` or similar service to keep models lean.
*   [ ] **Step 3.9: Harmonize `DataFieldEngine` & `StructuredWorkout` NP logic**: Ensure the rolling average and 4th-power math is shared between the live engine and the static workout analyzer.

### Phase 3D: [COMPLETED] Environment Removal
*   [x] **Step 3.10: Settings & Library ViewModels**: Create dedicated ViewModels for `SettingsView` and `WorkoutLibraryView` to remove their reliance on `@Environment`.
*   [x] **Step 3.11: Component Dependency Injection**: Refactor sub-components (like `WorkoutGraphView`, `WorkoutTargetHeader`, `LapsHistoryView`, `DataFieldTile`, `LapSummaryColumn`) to take dependencies via initializers instead of `@Environment`.
*   [x] **Step 3.12: App Entry Point Cleanup**: Remove all `.environment(...)` calls from `FitnessDeviceLabApp` to ensure a strictly explicit dependency graph.

### Phase 3E: DataFieldEngine Audit & Improvement
*   [ ] **Step 3.13: Metric Correctness Audit**: Verify the math in `DataFieldEngine` for NP, TSS, and IF. Ensure it handles gaps in data, pauses, and extreme altitude values correctly.
*   [ ] **Step 3.14: Concurrency & Performance Audit**: Review the `calculationTask` in `DataFieldEngine`. Ensure it doesn't leak memory or trigger unnecessary MainActor hops.
*   [ ] **Step 3.15: HRV Logic Validation**: Review `HRVEngine` and its integration to ensure metrics like DFA Alpha-1 are being calculated on valid, filtered RR-interval windows.

### Phase 3F: Workout Library Research & Design
*   [ ] **Step 3.16: Format Research**: Evaluate existing formats (Zwift `.zwo`, TrainerRoad, `.erg`, `.mrc`) vs. a custom JSON schema.
*   [ ] **Step 3.17: Storage Strategy Design**: Compare SwiftData vs. File-based storage (JSON/XML) for the library. Decide on a path that supports user customization and easy sharing.

### Phase 3G: Export Strategy
*   [ ] **Step 3.18: FIT Stability Confirmation**: Extensively test `FitEncoder` outputs in Garmin Connect/Strava.
*   [ ] **Step 3.19: TCX Deprecation**: Mark `TCXExporter` as deprecated and move it to a legacy support state (no new features).

### Phase 4: Verification & Integration
*   [ ] **Step 4.1: Unit Test `DataFieldEngine`**: Ensure all calculated metrics (NP, TSS, IF) are correct against a known set of power samples. Add tests for altitude-adjusted FTP.
*   [ ] **Step 4.2: Unit Test `WorkoutPlayerViewModel`**: Use the simulation layer to verify that UI actions (Pause, Lap, Stop) trigger the correct manager states.
*   [ ] **Step 4.3: End-to-End XCUITest**: Create a "Full Workout" UI test that runs a 1-minute simulated workout and verifies the export files are generated.

---

## 3. Testing Status Dashboard

| Component | Test Type | Status |
| :--- | :--- | :--- |
| `SensorDataParser` | Unit | ✅ Passed |
| `PhysicsUtilities` | Unit | ✅ Passed |
| `TargetPowerCalculator` | Unit | ✅ Passed (Step 3.5) |
| `WorkoutSessionManager` | Unit | ✅ Passed (Step 3.7.1) |
| `DataFieldEngine` | Unit | ❌ Missing |
| `WorkoutPlayerViewModel` | Unit | ❌ Missing |
| UI Workflows | UI (XCUITest) | ❌ Missing |

---
*Updated by Senior Engineering Consultant*
