# Design Spec: Swipeable Activity Profile Graphs

## Overview
Currently, the workout dashboard hardcodes which graphs to display (Main Workout Graph vs. DFA Alpha 1) based on the profile name. This design makes graphs configurable per `ActivityProfile` and provides a unified, swipeable horizontal container in the UI.

## Goals
- Make graphs configurable as part of the `ActivityProfile` definition.
- Support specialized graphs (Workout/Targets, DFA Alpha 1) and generic metric graphs.
- Provide a smooth "swipe" experience between multiple graphs in the dashboard.
- Maintain consistent X-axis (workout time) across all graphs.

## Proposed Changes

### 1. Data Model (`ActivityProfile.swift`)
- Introduce `GraphType` enum:
  - `.workout`: Power/HR/Cadence vs. Target blocks.
  - `.dfaAlpha1`: Specialized HRV visualization with 0.75/0.50 thresholds.
  - `.metric(DataFieldType)`: Generic line chart for any numeric field (e.g., `.speed`, `.cadence`).
- Add `public var graphs: [GraphType]` to `ActivityProfile`.
- Update static profiles:
  - `.defaultProfile`: `graphs = [.workout]`
  - `.dfaAnalysisProfile`: `graphs = [.workout, .dfaAlpha1]`

### 2. UI Components (`WorkoutViews.swift`)
- **`SwipeableGraphContainer`**: 
  - A `TabView` with `.page` style.
  - Fixed height (180pt) to ensure visual stability during swipes.
  - Integrated page indicator.
- **`GraphFactoryView`**: 
  - Dispatches to `WorkoutGraphView`, `DFAAlpha1ChartView`, or `GenericMetricGraphView` based on the `GraphType`.
- **`GenericMetricGraphView`**: 
  - A new reusable `Chart` component that plots a single `DataFieldType` over time using the recorder's trackpoints.

### 3. Dashboard Integration (`AdaptiveWorkoutDashboard.swift`)
- Replace hardcoded graph blocks in `sensorSetStackedSection` and `sensorSetSection` with the new `SwipeableGraphContainer`.
- Ensure the container receives the current `activeProfile.graphs`.

## Success Criteria
- [ ] Users can swipe horizontally between multiple graphs in a single dashboard section.
- [ ] The DFA Analysis profile shows both the Workout and DFA Alpha 1 graphs in the same space.
- [ ] Swiping the graph does not change the currently viewed data page (independent pagers).
- [ ] All graphs remain locked to the same X-axis timeline.
