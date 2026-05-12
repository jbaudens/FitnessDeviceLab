# Add Speed to Trackpoint and SessionRecorder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the `Trackpoint` model and `SessionRecorder` to include speed data.

**Architecture:** Update the `Trackpoint` struct in `Core/WorkoutModels.swift` and ensure `SessionRecorder` passes the speed from the `DataFieldEngine`.

**Tech Stack:** Swift, SwiftUI.

---

### Task 1: Update Trackpoint Model

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/Core/WorkoutModels.swift`

- [ ] **Step 1: Add speed property to Trackpoint**

```swift
public struct Trackpoint: Identifiable, Sendable, Codable {
    public let id: UUID
    public let time: Date
    public let hr: Int?
    public let power: Int?
    public let cadence: Int?
    public let altitude: Double?
    public let speed: Double? // Add this line
    public let powerBalance: Double?
    public let dfaAlpha1: Double?
    public let rrIntervals: [Double]

    public init(id: UUID = UUID(), time: Date, hr: Int? = nil, power: Int? = nil, cadence: Int? = nil, altitude: Double? = nil, speed: Double? = nil, powerBalance: Double? = nil, dfaAlpha1: Double? = nil, rrIntervals: [Double] = []) {
        self.id = id
        self.time = time
        self.hr = hr
        self.power = power
        self.cadence = cadence
        self.altitude = altitude
        self.speed = speed // Add this line
        self.powerBalance = powerBalance
        self.dfaAlpha1 = dfaAlpha1
        self.rrIntervals = rrIntervals
    }
}
```

- [ ] **Step 2: Verify it compiles**

### Task 2: Update SessionRecorder

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/Features/Workout/SessionRecorder.swift`

- [ ] **Step 1: Update pulse method to include speed**

```swift
    public func pulse(time: Date, altitude: Double?, rrIntervals: [Double], lapStartTime: Date?) {
        let pt = Trackpoint(
            time: time,
            hr: hrSource?.heartRate,
            power: powerSource?.cyclingPower,
            cadence: cadenceSource?.cadence,
            altitude: altitude,
            speed: engine.currentSpeed, // Add this line
            powerBalance: powerSource?.powerBalance,
            dfaAlpha1: engine.hrvMetrics.dfaAlpha1,
            rrIntervals: rrIntervals
        )
        // ...
    }
```

- [ ] **Step 2: Verify it compiles**

### Task 3: Build and Commit

- [ ] **Step 1: Build the project using xcodebuild**

Run: `xcodebuild -project FitnessDeviceLab/FitnessDeviceLab.xcodeproj -scheme FitnessDeviceLab -configuration Debug -sdk iphonesimulator build`

- [ ] **Step 2: Commit the changes**

Run: `git add . && git commit -m "feat: add speed to Trackpoint and SessionRecorder"`
