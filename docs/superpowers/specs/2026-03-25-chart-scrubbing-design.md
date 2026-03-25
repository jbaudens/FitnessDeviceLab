# Spec: Chart Scrubbing & Interactive Analysis

## Overview
Adds "Scrubbing" support to all performance charts in FitnessDeviceLab, allowing athletes to drag through workout history to see precise values and sensor deltas.

## UI/UX Design
- **Interaction**: Drag gesture on any chart activates a vertical playhead (RuleMark).
- **Feedback**: A fixed "Scrub Info Bar" at the top of the chart container displays precise metrics (Time, Power, Cadence, HR, or Delta) at the selected timestamp.
- **Occlusion Management**: By using a fixed bar instead of a floating tooltip, the data remains visible even when the user's finger is on the screen.
- **Haptics**: Light impact haptic feedback on activation/deactivation.

## Technical Architecture
- **State Management**: `selectedSeconds: Double?` managed via `@State` or `@Binding`.
- **Gesture Handling**: Swift Charts `.chartOverlay` with `DragGesture` and `proxy.value(atX:)`.
- **Synchronization**: In `DualPowerComparisonView`, state is shared across multiple charts to ensure synced scrubbing across Power and Delta views.
- **Efficiency**: O(1) data lookup based on the 1Hz indexed trackpoints.

## Implementation Scope
1. `DualPowerComparisonView`: Sync scrubbing between Overlay and Delta charts.
2. `WorkoutViews`: Add scrubbing to `PerformanceChart` and `GrowingPerformanceChart`.
3. `SummaryViews`: Ensure post-workout analysis supports the same interaction.
