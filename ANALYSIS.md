# Workout Analysis: Blackcap -1 Performance Issues

## Overview
Analysis of the TCX files provided in the `Examples/Blackcap -1` directory reveals a critical timing issue that explains the 10-15s "weird delay" reported during the last intervals of the workout.

## Key Findings

### 1. Significant Data Gaps
There are two major gaps in the recording where the app stopped logging trackpoints:
- **Gap 1:** 12 seconds missing between `20:05:54Z` and `20:06:06Z`.
- **Gap 2:** 5 seconds missing between `20:08:06Z` and `20:08:11Z`.

**Total data loss:** ~15 seconds of real-time recording.

### 2. Root Cause: Timer & Clock Synchronization
The gaps occurred at approximately **44-46 minutes** into the workout. This correlates with the user's observation of issues "in the last intervals."

In `WorkoutSessionManager.swift`, the workout clock is incremented linearly:
```swift
private func tick() {
    workoutElapsedTime += 1
    // ... update workout step based on workoutElapsedTime
}
```

Because `tick()` is triggered by a `Timer.publish(every: 1.0, ...)` on the `RunLoop.main`, any main thread blockage prevents the timer from firing. When the app eventually resumes (after a 12s block, for example), the `tick()` function is called only once. 

Consequently:
- The app's internal `workoutElapsedTime` only increments by **1 second**, despite **12 seconds** of real time having passed.
- This creates a **cumulative drift** where the app's workout state (current interval, target power) lags behind the user's real-time performance.
- By the end of the workout, the 15 seconds of cumulative gaps resulted in the target power changes appearing 15 seconds late.

### 3. Potential Performance Bottleneck
The `DataFieldEngine.calculateNPMetrics` function is a likely candidate for the main thread blocking. It currently performs an O(N * window) calculation (where N is total trackpoints) **every second** on the main thread. As the workout progresses towards 60 minutes, the overhead of recalculating Normalized Power (NP) for the entire session every second increases significantly, which could lead to the observed 12s and 5s "hangs."

## Recommended Fixes

1. **Clock Synchronization:** Change `WorkoutSessionManager` to calculate `workoutElapsedTime` based on the difference between `Date()` and `sessionStartTime`, rather than incrementing a counter. This will ensure the workout target power stays synced with real time, even if frames or timer ticks are dropped.
2. **Background Processing:** Move the heavy metric calculations in `DataFieldEngine` (especially NP and TSS) to a background thread or optimize them to be incremental.
3. **Timer Robustness:** Consider using a more robust timing mechanism or allowing the timer to "catch up" by checking the elapsed time on every tick.
