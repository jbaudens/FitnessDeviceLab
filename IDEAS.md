# Roadmap: Improvements & New Features

## 🚀 Priority Improvements

### Technical Debt & Robustness
*   **SwiftData Integration**: Replace current in-memory workout storage with `SwiftData` for persistent local workout history and sensor pairing memory.
*   **Enhanced BLE Reconnection**: Implement a "Background Reconnect" strategy to gracefully handle sensors that drop out mid-workout.
*   **Unit Test Expansion**: Increase coverage for `DataFieldEngine`'s NP/TSS calculations using edge-case trackpoint data.

### UX & UI Polish
*   **Tactile Alerts (Haptics)**: Use the Taptic Engine to provide physical feedback (vibrations) on the iPhone/iPad for critical events like:
    *   3-second countdown before a new interval.
    *   Warning if power/HR deviates significantly from the target.
    *   Confirmation of a manual lap or session start/stop.
*   **Enhanced Chart Interactivity**: While we have real-time power charts, we can add "Scrubbing" support—allowing you to drag your finger across the chart to see exact values and delta comparisons at specific time points.

---

## ✨ New Feature Ideas

### 1. Physiological & Training Analysis
*   **DFA Alpha 1 (Real-time)**: Use the `HRVEngine` to calculate DFA Alpha 1, allowing users to find their Aerobic Threshold (VT1) live during a ramp test.
*   **Power-Duration Curve**: Automatically update the user's "Best Efforts" (5s, 1min, 5min, 20min) after every session.

### 2. Ecosystem & Integration
*   **Strava/TrainingPeaks Sync**: Automatic upload of `.fit` files via OAuth integrations.
*   **iCloud Sync**: Sync `ActivityProfiles` and Workout Library across iPhone and iPad.
*   **Apple Watch Companion**: Use the Apple Watch as a Heart Rate source and secondary display for the iPhone app.

### 3. Simulation & Virtualization
*   **GPX Route Simulation**: Load a GPX file and have the `WorkoutPhysicsEngine` adjust trainer resistance based on the real-world gradient (Grade Simulation).
*   **Virtual Speed/Distance**: A more robust physics model that accounts for drafting and different bike types (Aero vs. Climbing).

### 4. Advanced Hardware Support
*   **Dual-Sided Power**: Breakdown of Left/Right balance and Torque Effectiveness/Pedal Smoothness metrics.
*   **Power Match 2.0**: A more sophisticated algorithm to make the smart trainer follow the power meter's readings with zero lag.
