import Foundation
import Observation

/// A dedicated manager to handle the lifecycle and storage of workout laps.
@Observable
public class LapManager {
    /// The collection of laps recorded in the current session.
    public private(set) var laps: [Lap] = []
    
    public init() {}
    
    /// Starts a new lap, closing the previous one if it exists.
    public func startNewLap(type: WorkoutStepType) {
        let now = Date()
        if var lastLap = laps.last {
            lastLap.endTime = now
            laps[laps.count - 1] = lastLap
        }
        
        let newLap = Lap(index: laps.count, startTime: now, type: type)
        laps.append(newLap)
    }
    
    /// Increments the active duration of the current lap.
    public func recordTick() {
        guard !laps.isEmpty else { return }
        laps[laps.count - 1].activeDuration += 1.0
    }
    
    /// Resets the lap history for a new session.
    public func reset() {
        laps = []
    }
    
    /// Returns the current active lap, if any.
    public var currentLap: Lap? {
        laps.last
    }
    
    /// Total count of laps.
    public var lapCount: Int {
        laps.count
    }
}
