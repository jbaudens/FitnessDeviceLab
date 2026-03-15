import Foundation
import Combine
import Observation

@Observable
public class WorkoutSessionManager {
    public enum DataFieldMode: String, CaseIterable, Identifiable {
        case session = "Session"
        case lap = "Lap"
        public var id: String { rawValue }
    }
    
    public var currentDataFieldMode: DataFieldMode = .session
    
    // MARK: - Recorders (Injected from outside)
    public var recorderA: SessionRecorder
    public var recorderB: SessionRecorder
    
    // MARK: - Global Workout Control
    public var controlSource: ControllableTrainer?
    
    // MARK: - Workout State
    public var isRecording = false
    public var isLoaded = false
    public var isPaused = false
    
    public var sessionStartTime: Date?
    public var workoutElapsedTime: TimeInterval = 0
    
    public var activeProfile: ActivityProfile = .defaultProfile
    public var selectedWorkout: StructuredWorkout?
    public var ergModeEnabled = false
    public var resistanceLevel: Double = 40.0
    public var workoutDifficultyScale: Double = 1.0
    
    public var currentStepIndex: Int = 0
    public var timeInStep: TimeInterval = 0
    public var currentTargetPower: Int? = nil
    public var currentTargetHR: Int? = nil
    
    public var laps: [Lap] = []
    
    private var lastSentTargetPower: Int?
    private var lastSentResistanceLevel: Double?
    
    // HR Control State
    private var hrControlBaseWatts: Double?
    private var lastHRUpdate: Date?
    
    public var engineA: DataFieldEngine
    public var engineB: DataFieldEngine
    
    public var exportedFiles: [URL] = []
    
    private var timerCancellable: AnyCancellable?
    private let settings: SettingsProvider
    private let locationProvider: LocationProvider
    
    public init(settings: SettingsProvider, locationProvider: LocationProvider) {
        self.settings = settings
        self.locationProvider = locationProvider
        let recA = SessionRecorder(settings: settings)
        let recB = SessionRecorder(settings: settings)
        self.recorderA = recA
        self.recorderB = recB
        self.engineA = DataFieldEngine(recorder: recA, settings: settings)
        self.engineB = DataFieldEngine(recorder: recB, settings: settings)
    }
    
    /// Starts the workout orchestration with the provided recorders and control source.
    public func startWorkout(recA: SessionRecorder, recB: SessionRecorder, control: ControllableTrainer?) {
        self.recorderA = recA
        self.recorderB = recB
        self.controlSource = control
        
        // Re-initialize engines with the new recorders
        self.engineA = DataFieldEngine(recorder: recA, settings: settings)
        self.engineB = DataFieldEngine(recorder: recB, settings: settings)
        
        workoutElapsedTime = 0
        currentStepIndex = 0
        timeInStep = 0
        laps = []
        isPaused = false
        isRecording = false
        exportedFiles = []
        
        recorderA.prepare()
        recorderB.prepare()
        
        isLoaded = true
        
        // Start the master clock
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.tick()
                }
            }
    }
    
    public func startRecording() {
        guard isLoaded, !isRecording else { return }
        
        let initialStepType = selectedWorkout?.steps.first?.type ?? .work
        startNewLap(type: initialStepType)
        
        sessionStartTime = Date()
        isRecording = true
        isPaused = false
        
        recorderA.isRecording = true
        recorderB.isRecording = true
    }
    
    public func pauseWorkout() {
        guard isRecording else { return }
        isPaused = true
        recorderA.isRecording = false
        recorderB.isRecording = false
    }
    
    public func resumeWorkout() {
        guard isRecording else { return }
        isPaused = false
        recorderA.isRecording = true
        recorderB.isRecording = true
    }
    
    public func manualLap() {
        guard isRecording else { return }
        let currentStepType = currentWorkoutStep?.type ?? .work
        startNewLap(type: currentStepType)
    }
    
    public func increaseDifficulty() {
        workoutDifficultyScale = min(2.0, workoutDifficultyScale + 0.01)
    }
    
    public func decreaseDifficulty() {
        workoutDifficultyScale = max(0.5, workoutDifficultyScale - 0.01)
    }
    
    public var canEnableErgMode: Bool {
        controlSource != nil
    }
    
    private func startNewLap(type: WorkoutStepType) {
        let now = Date()
        if var lastLap = laps.last {
            lastLap.endTime = now
            laps[laps.count - 1] = lastLap
        }
        
        let newLap = Lap(index: laps.count, startTime: now, type: type)
        laps.append(newLap)
    }
    
    @MainActor
    private func tick() {
        let now = Date()
        let altitude = locationProvider.currentAltitude ?? settings.altitudeOverride
        
        recorderA.recordPoint(time: now, altitude: altitude)
        recorderB.recordPoint(time: now, altitude: altitude)
        
        let lapStart = laps.last?.startTime
        engineA.updateMetrics(from: recorderA.trackpoints, lapStartTime: lapStart)
        engineB.updateMetrics(from: recorderB.trackpoints, lapStartTime: lapStart)
        
        guard isRecording else { return }
        guard !isPaused else { return }
        
        workoutElapsedTime += 1.0
        let totalElapsed = workoutElapsedTime
        
        if !laps.isEmpty {
            laps[laps.count - 1].activeDuration += 1.0
        }
        
        if let workout = selectedWorkout {
            var accumulated: TimeInterval = 0
            var foundStep = false
            for (index, step) in workout.steps.enumerated() {
                if totalElapsed < accumulated + step.duration {
                    if currentStepIndex != index {
                        currentStepIndex = index
                        startNewLap(type: step.type)
                    }
                    timeInStep = totalElapsed - accumulated
                    foundStep = true
                    break
                }
                accumulated += step.duration
            }
            
            if !foundStep && !workout.steps.isEmpty {
                stopWorkout()
                return
            }
            
            if let step = currentWorkoutStep {
                let isFinished = currentStepIndex >= workout.steps.count - 1 && timeInStep >= workout.steps.last?.duration ?? 0
                
                // 1. Determine the "Goal" for UI
                let ftp = settings.userFTP
                let lthr = Double(settings.userLTHR)
                if let hrPercent = step.targetHeartRatePercent {
                    currentTargetHR = Int(round(hrPercent * workoutDifficultyScale * lthr))
                    currentTargetPower = nil
                } else {
                    currentTargetPower = Int(round((step.powerAt(time: timeInStep) ?? 0) * workoutDifficultyScale * ftp))
                    currentTargetHR = nil
                }
                
                // 2. Determine the "Setpoint" for Hardware
                let nextStep: WorkoutStep? = (currentStepIndex < workout.steps.count - 1) ? workout.steps[currentStepIndex + 1] : nil
                
                let input = TrainerSetpointCalculator.Input(
                    currentStep: step,
                    nextStep: nextStep,
                    timeInStep: timeInStep,
                    isFinished: isFinished,
                    ftp: ftp,
                    lthr: lthr,
                    difficultyScale: workoutDifficultyScale,
                    ergModeEnabled: ergModeEnabled,
                    currentHR: recorderA.hrSource?.heartRate,
                    previousHRControlBaseWatts: hrControlBaseWatts
                )
                
                let result = TrainerSetpointCalculator.calculate(input: input)
                let setpointWatts = result.setpointWatts
                self.hrControlBaseWatts = result.newHRControlBaseWatts
                
                // 3. Command the Trainer
                if let trainer = controlSource {
                    if ergModeEnabled {
                        if let targetWatts = setpointWatts {
                            if targetWatts != lastSentTargetPower {
                                trainer.setTargetPower(targetWatts)
                                lastSentTargetPower = targetWatts
                            }
                            lastSentResistanceLevel = nil
                        }
                    } else {
                        if lastSentTargetPower != nil || lastSentResistanceLevel != resistanceLevel {
                            trainer.setResistanceLevel(resistanceLevel)
                            lastSentResistanceLevel = resistanceLevel
                            lastSentTargetPower = nil
                        }
                    }
                }
            } else {
                currentTargetPower = nil
                currentTargetHR = nil
                hrControlBaseWatts = nil
            }
        } else {
            if let trainer = controlSource {
                if lastSentResistanceLevel != resistanceLevel {
                    trainer.setResistanceLevel(resistanceLevel)
                    lastSentResistanceLevel = resistanceLevel
                }
            }
        }
    }
    
    public func stopWorkout() {
        isRecording = false
        isLoaded = false
        isPaused = false
        
        recorderA.isRecording = false
        recorderB.isRecording = false
        
        timerCancellable?.cancel()
        timerCancellable = nil
        
        Task { @MainActor in
            var files: [URL] = []
            files.append(contentsOf: recorderA.stop(label: "ProfileA", laps: laps))
            files.append(contentsOf: recorderB.stop(label: "ProfileB", laps: laps))
            
            if !files.isEmpty {
                exportedFiles = files
            }
        }
    }
    
    public var currentWorkoutStep: WorkoutStep? {
        guard let workout = selectedWorkout, currentStepIndex < workout.steps.count else { return nil }
        return workout.steps[currentStepIndex]
    }
}
