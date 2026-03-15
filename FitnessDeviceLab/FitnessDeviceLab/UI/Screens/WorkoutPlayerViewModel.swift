import Foundation
import Observation
import SwiftUI
import Combine

@Observable
@MainActor
public class WorkoutPlayerViewModel {
    public var workoutManager: WorkoutSessionManager
    public var bluetoothManager: BluetoothManager
    public let settings: SettingsProvider
    
    public var recorderA: SessionRecorder { workoutManager.recorderA }
    public var recorderB: SessionRecorder { workoutManager.recorderB }
    public var controlSource: ControllableTrainer?
    
    public var showingStopConfirmation = false
    public var showingDiscardConfirmation = false
    
    public init(workoutManager: WorkoutSessionManager, bluetoothManager: BluetoothManager, settings: SettingsProvider) {
        self.workoutManager = workoutManager
        self.bluetoothManager = bluetoothManager
        self.settings = settings
    }
    
    // MARK: - Role-Specific Adaptor Lists for UI Pickers
    
    public var availableHRSensors: [HeartRateSensor] {
        bluetoothManager.peripherals.compactMap { HeartRateSensor(peripheral: $0) }
    }
    
    public var availablePowerSensors: [PowerSensor] {
        bluetoothManager.peripherals.compactMap { PowerSensor(peripheral: $0) }
    }
    
    public var availableCadenceSensors: [CadenceSensor] {
        bluetoothManager.peripherals.compactMap { CadenceSensor(peripheral: $0) }
    }
    
    public var availableTrainers: [ControllableTrainer] {
        bluetoothManager.peripherals.compactMap { ControllableTrainer(peripheral: $0) }
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
        !workoutManager.exportedFiles.isEmpty
    }
    
    public var isActiveState: Bool {
        workoutManager.isLoaded || workoutManager.isRecording
    }
    
    // MARK: - Actions
    
    public func loadWorkout() {
        // Resolve Control Source from Recorder A's power selection if it's a trainer
        if let pwrA = recorderA.powerSource {
            // Find the peripheral that matches Power A and see if it's also a trainer
            if let peripheral = bluetoothManager.peripherals.first(where: { $0.id == pwrA.id }),
               let trainer = ControllableTrainer(peripheral: peripheral) {
                self.controlSource = trainer
            }
        }
        
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
