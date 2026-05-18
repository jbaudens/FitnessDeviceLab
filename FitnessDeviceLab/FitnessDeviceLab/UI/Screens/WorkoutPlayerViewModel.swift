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
        
        chartPointsA = downsample(recorderA.trackpoints, targetCount: targetPointCount)
        chartPointsB = downsample(recorderB.trackpoints, targetCount: targetPointCount)
        
        lastDownsampleTime = now
    }
    
    private func downsample(_ points: [Trackpoint], targetCount: Int) -> [Trackpoint] {
        guard points.count > targetCount else { return points }
        
        // We use a bucket-based approach to ensure stability.
        // Instead of stride over indices (which shift as count grows),
        // we divide the data into fixed buckets and pick representative points.
        
        let bucketSize = points.count / targetCount
        var result: [Trackpoint] = []
        result.reserveCapacity(targetCount + 1)
        
        // Always include the first point
        if let first = points.first {
            result.append(first)
        }
        
        // Process internal buckets
        // For each bucket, we pick the point with the highest power/value to preserve visual peaks
        for bucketIndex in 0..<targetCount {
            let start = bucketIndex * bucketSize
            let end = min(start + bucketSize, points.count)
            
            if start < end {
                // Find point with highest "signal" (power or hr) in this bucket
                // This preserves peaks better than simple striding
                var bestPoint = points[start]
                var maxVal = Double(bestPoint.power ?? bestPoint.hr ?? 0)
                
                for j in start..<end {
                    let p = points[j]
                    let val = Double(p.power ?? p.hr ?? 0)
                    if val > maxVal {
                        maxVal = val
                        bestPoint = p
                    }
                }
                
                if result.last?.id != bestPoint.id {
                    result.append(bestPoint)
                }
            }
        }
        
        // Always include the absolute last point to keep the chart "live"
        if let last = points.last, result.last?.id != last.id {
            result.append(last)
        }
        
        return result
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
