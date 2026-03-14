# Analysis of UI Lockup during Page Swiping

## Issue Description
The application experiences severe lag or a complete UI lockup (freeze) when swiping between data field pages during an active workout session. The severity of the lockup increases as the workout duration progresses.

## Root Cause Analysis

### 1. Synchronous Heavy Calculations in View Rendering
The primary cause of the lockup is the synchronous execution of heavy data processing logic within the SwiftUI `View` body. Specifically, the `DataFieldType.value(for:engine:workoutManager:)` function in `DataFieldViews.swift` performs a full recalculation of workout metrics every time a data tile is rendered.

#### Problematic Code (DataFieldViews.swift):
```swift
func value(for engine: DataFieldEngine, workoutManager: WorkoutSessionManager? = nil) -> Double? {
    // ...
    let m: CalculatedMetrics = {
        let settings = SettingsManager.shared.metricsSettings
        guard let wm = workoutManager, wm.currentDataFieldMode == .lap, let currentLap = wm.laps.last else {
            return sessionMetrics
        }
        // CRITICAL: filtering and calculating metrics synchronously on the Main Thread
        let points = engine.recorder.trackpoints.filter { $0.time >= currentLap.startTime }
        return DataFieldEngine.calculate(from: points, settings: settings)
    }()
    // ...
}
```

When the `currentDataFieldMode` is set to `.lap`, or when viewing specific lap-based fields (like `lapAvgPower`, `lapNP`, etc.), the app:
1.  Filters the entire `trackpoints` array.
2.  Passes the subset to `DataFieldEngine.calculate`.
3.  `DataFieldEngine.calculate` performs multiple iterations and math operations (Power, HR, Cadence).
4.  If the lap is longer than 30 seconds, it calls `calculateNPMetrics`, which has an **O(N^2)** complexity for Normalized Power (NP) calculation.

#### Impact during Swiping:
Swiping a `TabView` with `PageTabViewStyle` causes SwiftUI to instantiate and render multiple pages (the current, previous, and next) to ensure a smooth transition. If each page contains 6-9 data tiles, and each tile triggers an $O(N^2)$ calculation on the main thread, the CPU becomes completely saturated, leading to the freeze.

### 2. Main Thread Contention
While `DataFieldEngine` attempts to offload "Session" metrics to a background `Task`, the "Lap" metrics logic in the view layer completely bypasses this safety mechanism. The Main Thread is forced to wait for these calculations to complete before it can process the next frame of the swipe animation.

### 3. Redundant Calculations
Since each `DataFieldTile` is an independent view, if you have 6 tiles on a page all showing lap-based metrics, the exact same lap subset is filtered and recalculated 6 times per frame.

### 4. Chart Rendering Complexity
`WorkoutGraphView` and `PerformanceChart` (using Swift Charts) add further rendering overhead. Although `PerformanceChart` implements downsampling, it still executes its logic during the `body` property evaluation, which adds to the cumulative frame time budget.

## Proposed Strategy for Resolution (For Future Implementation)

1.  **Centralize Lap Calculations**: Move the current lap's metric calculations into `DataFieldEngine`. Just as there is a `@Published var calculatedMetrics` for the whole session, there should be a `currentLapMetrics` that is updated in the same background `Task`.
2.  **View Layer Optimization**: `DataFieldType.value` should only return already-computed values stored in the engine, rather than triggering new calculations.
3.  **Throttling**: Ensure that heavy background calculations (like NP/TSS) are throttled (e.g., once per second) rather than happening on every single data point update if the UI can't keep up.
4.  **Memoization**: Cache the results of lap calculations so that multiple tiles on the same screen don't repeat the work.

---
*Analysis completed on March 13, 2026*
