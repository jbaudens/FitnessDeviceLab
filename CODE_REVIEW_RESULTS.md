# Code Review Findings

## Phase 1: Core Domain & Physics Engines
- **Core Domain:** `ActivityProfile` and `DataPage` are structurally sound structs that implement `Codable` using synthesized logic. A potential risk was identified in the use of `var id = UUID()` within Codable structs (synthesized decoding will fail if the `id` key is missing from the data unless a custom initializer is provided). `DataFieldType` is a String-backed enum, which is safe for `Codable`. Further investigation is needed for `Workout.swift` and `Workouts.swift` for explicit `Sendable` conformance. `AppError.swift` and `Protocols.swift` should also be checked for `Sendable` compliance.
- **Physics Engines:** The architecture is robust for handling fitness data. `DataFieldEngine` effectively uses `Task.detached` with `.userInitiated` priority to offload heavy 'complex' metrics (Normalized Power, TSS, HRV) from the main thread to prevent UI stutters. Updates to `@Observable` state are safely performed on the main thread via `await MainActor.run`. Most other engines (`HRVEngine`, `PowerMath`, `PhysicsUtilities`) are stateless utility structures with `nonisolated` static methods.
- **Recommendation:** Introduce a dedicated `ComputationActor` to formalize the isolation of heavy math instead of using ad-hoc `Task.detached`. Consider moving the core accumulation logic of `DataFieldEngine` to an `actor` and only publishing summary updates to the `@Observable` view model to reduce `MainActor` contention.

## Phase 2: Services & External Integrations
- **Dependency Injection:** `BluetoothManager` follows good practices by accepting `SettingsProvider` and `ErrorManager` in its initializer. However, `DiscoveredPeripheral` instantiates its own handlers (`HeartRateHandler`, `PowerMeterHandler`, `FTMSHandler`), bypassing DI and reducing testability.
- **Retain Cycles:** The codebase correctly uses `[weak self]` in closures (e.g., in `BluetoothManager` interactions with `RealBluetoothDriver`). Using the `@Observable` framework mitigates many traditional `Combine`-related retain cycle risks.
- **Error Handling:** `ErrorManager` provides robust, centralized error reporting for Bluetooth states (powered off, unauthorized, connection failures).
- **Data Parsing Safety:** `SensorDataParser` relies heavily on `guard` statements for bounds checking. While generally safe, the complexity of FTMS and Cycling Power flags necessitates meticulous verification against minimum byte lengths to prevent index out-of-range crashes.
- **Recommendation:** Refactor `DiscoveredPeripheral` to accept its handlers via a factory or dependency injection. Expand exhaustive unit testing for `SensorDataParser` against truncated or malformed BLE packets.

## Phase 3: Features & ViewModels
- **State Management & Separation:** The codebase successfully utilizes the modern Swift `@Observable` macro for efficient UI updates, strictly separating UI from business logic. Business logic is heavily centralized within the `Features` layer (e.g., `WorkoutSessionManager`).
- **Fat Components:** `WorkoutSessionManager` has grown into a "fat" manager. It orchestrates state tracking, hardware control, timer management, and workout step logic, violating the Single Responsibility Principle. This complexity makes it harder to test in isolation.
- **ViewModels:** The ViewModels (like `WorkoutPlayerViewModel` and `WorkoutEditorViewModel`) are generally well-structured as lean conduits connecting the UI to the underlying Managers.
- **Recommendation:** Decompose `WorkoutSessionManager` into smaller, focused service components (e.g., a `WorkoutStateMachine` for step logic and a `HardwareOrchestrator` for trainer/sensor commands).

## Phase 4: UI Components & Screens
- **SwiftUI Performance:** The UI utilizes modern tools (`NavigationStack`, `@Observable`) and demonstrates strong modular patterns (`DataFieldType` enum). However, performance bottlenecks exist due to the 1Hz hardware update tick triggering large, indiscriminate redraws of complex view hierarchies (`WorkoutPlayerView`, `AdaptiveWorkoutDashboard`).
- **Heavy View Calculations:** Views like `WorkoutGraphView` and `AdaptiveWorkoutDashboard` perform heavy mathematical calculations (scaling domains, calculating layout deltas) directly in their `body` property. Since the body runs every second during a workout, this is highly inefficient.
- **Accessibility & HIG:** Custom components lack explicit accessibility labels and traits. Flexible layouts for Dynamic Type could be improved.
- **Recommendation:** Extract heavy calculations from `View.body` into `ViewModel` properties or `Task` operations. Introduce `EquatableView` or granular state bindings (`@Observable` split into finer sub-objects) to prevent the entire `WorkoutPlayerView` hierarchy from redrawing on every 1Hz data tick.
