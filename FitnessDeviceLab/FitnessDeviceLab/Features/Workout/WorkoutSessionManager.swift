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
    
    public var engineA: DataFieldEngine
    public var engineB: DataFieldEngine
    private let setpointCalculator = TrainerSetpointCalculator()
    private let workoutTimer: WorkoutTimer
    
    public var exportedFiles: [URL] = []
    
    private let settings: SettingsProvider
    private let locationProvider: LocationProvider
    
    public init(settings: SettingsProvider, locationProvider: LocationProvider, workoutTimer: WorkoutTimer) {
        self.settings = settings
        self.locationProvider = locationProvider
        self.workoutTimer = workoutTimer
        
        let recA = SessionRecorder(settings: settings)
        let recB = SessionRecorder(settings: settings)
        self.recorderA = recA
        self.recorderB = recB
        self.engineA = DataFieldEngine(recorder: recA, settings: settings)
        self.engineB = DataFieldEngine(recorder: recB, settings: settings)
        
        setupTimerCallback()
    }
    
    private func setupTimerCallback() {
        workoutTimer.onTick = { [weak self] in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    /// Starts the workout orchestration with the provided recorders and control source.
    public func startWorkout(recA: SessionRecorder, recB: SessionRecorder, control: ControllableTrainer?) {
        // We use the passed recorders (usually the ones owned by the manager or VM)
        self.recorderA = recA
        self.recorderB = recB
        self.controlSource = control
        
        // Link recorders to engines
        self.engineA = DataFieldEngine(recorder: recA, settings: settings)
        self.engineB = DataFieldEngine(recorder: recB, settings: settings)
        setpointCalculator.reset()
        
        workoutElapsedTime = 0
        currentStepIndex = 0
        timeInStep = 0
        laps = []
        isPaused = false
        isRecording = false
        exportedFiles = []
        
        // NOTE: We DO NOT call recorder.prepare() here if it clears sources.
        // We only clear the data points.
        recorderA.trackpoints.removeAll()
        recorderB.trackpoints.removeAll()
        
        isLoaded = true
        
        // Start the timer
        workoutTimer.start()
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
        workoutTimer.pause()
    }
    
    public func resumeWorkout() {
        guard isRecording else { return }
        isPaused = false
        recorderA.isRecording = true
        recorderB.isRecording = true
        workoutTimer.resume()
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
        
        // 1. Capture sensor data once to avoid clearing shared RR intervals between recorders
        let rrIntervals = recorderA.hrSource?.latestRRIntervals ?? []
        recorderA.hrSource?.latestRRIntervals.removeAll()
        
        // 2. Update both recorders
        recorderA.recordPoint(time: now, altitude: altitude, rrIntervals: rrIntervals)
        recorderB.recordPoint(time: now, altitude: altitude, rrIntervals: rrIntervals)
        
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
                
                // 2. Determine the "Setpoint" for Hardware (Only in ERG mode)
                if ergModeEnabled, let trainer = controlSource {
                    let nextStep: WorkoutStep? = (currentStepIndex < workout.steps.count - 1) ? workout.steps[currentStepIndex + 1] : nil
                    
                    let input = TrainerSetpointCalculator.Input(
                        currentStep: step,
                        nextStep: nextStep,
                        timeInStep: timeInStep,
                        isFinished: isFinished,
                        ftp: ftp,
                        lthr: lthr,
                        difficultyScale: workoutDifficultyScale,
                        currentHR: recorderA.hrSource?.heartRate
                    )
                    
                    if let targetWatts = setpointCalculator.calculate(input: input) {
                        if targetWatts != lastSentTargetPower {
                            trainer.setTargetPower(targetWatts)
                            lastSentTargetPower = targetWatts
                        }
                        lastSentResistanceLevel = nil
                    }
                } else if let trainer = controlSource {
                    // Resistance Mode: Send manual resistance level if it changed or if we were previously in ERG mode
                    if lastSentTargetPower != nil || lastSentResistanceLevel != resistanceLevel {
                        trainer.setResistanceLevel(resistanceLevel)
                        lastSentResistanceLevel = resistanceLevel
                        lastSentTargetPower = nil
                    }
                }
            } else {
                currentTargetPower = nil
                currentTargetHR = nil
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
        
        setpointCalculator.reset()
        workoutTimer.stop()
        
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
