import Foundation
import Observation
import Combine

@Observable
@MainActor
public class WorkoutPlayerViewModel {
    public var workoutManager: WorkoutSessionManager
    public var bluetoothManager: BluetoothManager
    public let settings: SettingsProvider
    
    public var recorderA: SessionRecorder
    public var recorderB: SessionRecorder
    public var controlSource: ControllableTrainer?
    
    public var chartPointsA: [Trackpoint] = []
    public var chartPointsB: [Trackpoint] = []
    
    public var showingStopConfirmation = false
    public var showingDiscardConfirmation = false
    public var showingComparison = false
    
    private var lastDownsampleTime: Date = .distantPast
    private let downsampleThreshold: TimeInterval = 1.0
    private let targetPointCount = 500

    public init(workoutManager: WorkoutSessionManager, bluetoothManager: BluetoothManager, settings: SettingsProvider) {
        self.workoutManager = workoutManager
        self.bluetoothManager = bluetoothManager
        self.settings = settings
        self.recorderA = SessionRecorder(settings: settings)
        self.recorderB = SessionRecorder(settings: settings)
        
        setupDownsampling()
    }
    
    // MARK: - Downsampling Logic
    
    private func setupDownsampling() {
        withObservationTracking {
            _ = recorderA.trackpoints.count
            _ = recorderB.trackpoints.count
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.throttledDownsample()
                self.setupDownsampling()
            }
        }
    }
    
    private func throttledDownsample() {
        let now = Date()
        guard now.timeIntervalSince(lastDownsampleTime) >= downsampleThreshold else { return }
        
        // We use a fixed time-based bucket approach for absolute stability.
        // As the workout grows, we increase the bucket duration (2s, 5s, 10s...)
        // but we only change it when we absolutely must to stay under targetPointCount.
        
        chartPointsA = downsample(recorderA.trackpoints, targetCount: targetPointCount)
        chartPointsB = downsample(recorderB.trackpoints, targetCount: targetPointCount)
        
        lastDownsampleTime = now
    }
    
    private func downsample(_ points: [Trackpoint], targetCount: Int) -> [Trackpoint] {
        guard points.count > targetCount, let firstTime = points.first?.time, let lastTime = points.last?.time else { return points }
        
        let totalDuration = lastTime.timeIntervalSince(firstTime)
        
        // Calculate a stable bucket duration (e.g. 1s, 2s, 5s, 10s, 30s, 60s)
        // This prevents the bucket size from "jittering" on every new point.
        let rawBucketDuration = totalDuration / Double(targetCount)
        let stableBucketDuration: TimeInterval
        if rawBucketDuration <= 1.0 { stableBucketDuration = 1.0 }
        else if rawBucketDuration <= 2.0 { stableBucketDuration = 2.0 }
        else if rawBucketDuration <= 5.0 { stableBucketDuration = 5.0 }
        else if rawBucketDuration <= 10.0 { stableBucketDuration = 10.0 }
        else if rawBucketDuration <= 30.0 { stableBucketDuration = 30.0 }
        else { stableBucketDuration = 60.0 }

        var result: [Trackpoint] = []
        result.reserveCapacity(Int(totalDuration / stableBucketDuration) + 2)
        
        var currentBucketStartTime = firstTime
        var bestPointInBucket: Trackpoint?
        var maxImportance: Double = -1.0
        
        for p in points {
            let offset = p.time.timeIntervalSince(currentBucketStartTime)
            
            if offset >= stableBucketDuration {
                // Close current bucket
                if let best = bestPointInBucket {
                    result.append(best)
                }
                
                // Start new bucket
                currentBucketStartTime += (floor(offset / stableBucketDuration) * stableBucketDuration)
                bestPointInBucket = p
                maxImportance = calculateImportance(p)
            } else {
                // Update best point in current bucket
                let importance = calculateImportance(p)
                if importance > maxImportance {
                    maxImportance = importance
                    bestPointInBucket = p
                }
            }
        }
        
        // Always include the absolute last point
        if let last = points.last, result.last?.id != last.id {
            result.append(last)
        }
        
        return result
    }
    
    private func calculateImportance(_ p: Trackpoint) -> Double {
        // Importance is a heuristic to pick the most "interesting" point in a bucket.
        // We favor peaks in Power, but also check for HR and DFA Alpha-1 presence.
        let pwr = Double(p.power ?? 0)
        let hr = Double(p.hr ?? 0)
        let dfa = p.dfaAlpha1 != nil ? 100.0 : 0.0 // Prioritize points with DFA a1 data
        return pwr + (hr * 0.5) + dfa
    }
    
    // MARK: - Role-Specific Adaptor Lists for UI Pickers (Connected Only)
    
    public var availableHRSensors: [HeartRateSensor] {
        bluetoothManager.peripherals
            .filter { $0.isConnected }
            .compactMap { HeartRateSensor(peripheral: $0) }
    }
    
    public var availablePowerSensors: [PowerSensor] {
        bluetoothManager.peripherals
            .filter { $0.isConnected }
            .compactMap { PowerSensor(peripheral: $0) }
    }
    
    public var availableCadenceSensors: [CadenceSensor] {
        bluetoothManager.peripherals
            .filter { $0.isConnected }
            .compactMap { CadenceSensor(peripheral: $0) }
    }
    
    public var availableTrainers: [ControllableTrainer] {
        bluetoothManager.peripherals
            .filter { $0.isConnected }
            .compactMap { ControllableTrainer(peripheral: $0) }
    }
    
    // UI Helpers for Sources from Recorders
    public var hrA: HeartRateSensor? { recorderA.hrSource }
    public var powerA: PowerSensor? { recorderA.powerSource }
    public var cadenceA: CadenceSensor? { recorderA.cadenceSource }
    
    public var hrB: HeartRateSensor? { recorderB.hrSource }
    public var powerB: PowerSensor? { recorderB.powerSource }
    public var cadenceB: CadenceSensor? { recorderB.cadenceSource }
    
    // MARK: - Computed Properties for View
    
    public func deviceNames(recorder: SessionRecorder) -> String {
        let names = [
            recorder.hrSource?.name,
            recorder.powerSource?.name,
            recorder.cadenceSource?.name
        ].compactMap { $0 }
        
        let uniqueNames = Array(Set(names)).sorted()
        return uniqueNames.isEmpty ? "No Sensors" : uniqueNames.joined(separator: " + ")
    }
    
    public var isSummaryState: Bool {
        !workoutManager.exportedFiles.isEmpty && !workoutManager.isRecording
    }
    
    public var isActiveState: Bool {
        (workoutManager.isLoaded || workoutManager.isRecording) && !isSummaryState
    }
    
    // MARK: - Actions
    
    public func loadWorkout() {
        workoutManager.startWorkout(recA: recorderA, recB: recorderB, control: controlSource)
    }
    
    public func discardSession() {
        workoutManager.exportedFiles = []
    }
    
    public func clearAllSelections() {
        recorderA.hrSource = nil
        recorderA.powerSource = nil
        recorderA.cadenceSource = nil
        
        recorderB.hrSource = nil
        recorderB.powerSource = nil
        recorderB.cadenceSource = nil
        
        controlSource = nil
        workoutManager.selectedWorkout = nil
    }
    
    public func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
