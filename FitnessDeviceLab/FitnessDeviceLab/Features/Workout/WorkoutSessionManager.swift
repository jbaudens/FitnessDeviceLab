import Foundation
import Combine
import Observation

@Observable
public class WorkoutSessionManager {
    // MARK: - Recorders (Injected from outside)
    public var recorderA: SessionRecorder
    public var recorderB: SessionRecorder
    
    // MARK: - Controller Components
    public let trainerController = TrainerController()
    private let setpointCalculator = TrainerSetpointCalculator()
    private let sessionTimer: SessionTimer
    
    // MARK: - Workout State
    public enum FreeRideControlMode: String, Codable, CaseIterable, Identifiable {
        case resistance = "Resistance"
        case power = "Power (ERG)"
        case heartRate = "Heart Rate (ERG)"
        public var id: String { rawValue }
    }
    
    public var freeRideControlMode: FreeRideControlMode = .resistance
    public var manualTargetPower: Int = 100
    public var manualTargetHR: Int = 130
    
    public var isRecording = false
    public var isLoaded = false
    public var isPaused = false
    public var isSaving = false
    
    public var sessionStartTime: Date?
    public var workoutElapsedTime: TimeInterval { sessionTimer.elapsedTime }
    
    public var activeProfile: ActivityProfile = .defaultProfile
    public var selectedWorkout: StructuredWorkout?
    public var ergModeEnabled = false
    public var resistanceLevel: Double = 40.0
    public var workoutDifficultyScale: Double = 1.0
    
    public var currentStepIndex: Int = 0
    public var timeInStep: TimeInterval = 0
    public var currentTargetPower: Int? = nil
    public var currentTargetHR: Int? = nil
    
    let lapManager = LapManager()
    public var laps: [Lap] { lapManager.laps }
    
    public var exportedFiles: [URL] = []
    
    public let settings: SettingsProvider
    private let locationProvider: LocationProvider
    private let errorManager: ErrorManager?
    
    public init(settings: SettingsProvider, 
                locationProvider: LocationProvider, 
                sessionTimer: SessionTimer,
                recorderA: SessionRecorder,
                recorderB: SessionRecorder,
                errorManager: ErrorManager? = nil) {
        self.settings = settings
        self.locationProvider = locationProvider
        self.sessionTimer = sessionTimer
        self.recorderA = recorderA
        self.recorderB = recorderB
        self.errorManager = errorManager
        
        // Default manual targets to user-specific values
        self.manualTargetPower = Int(settings.userFTP * 0.6)
        self.manualTargetHR = settings.userLTHR - 20
        
        setupTimerCallback()
    }
    
    private func setupTimerCallback() {
        sessionTimer.onTick = { [weak self] in
            self?.tick()
        }
    }
    
    /// Starts the workout orchestration with the provided recorders and control source.
    public func startWorkout(recA: SessionRecorder, recB: SessionRecorder, control: ControllableTrainer?) {
        // We use the passed recorders (usually the ones owned by the manager or VM)
        self.recorderA = recA
        self.recorderB = recB
        self.trainerController.trainer = control
        
        setpointCalculator.reset()
        trainerController.reset()
        lapManager.reset()
        
        sessionTimer.reset()
        currentStepIndex = 0
        timeInStep = 0
        isPaused = false
        isRecording = false
        isSaving = false
        exportedFiles = []
        
        // Set default manual targets if no workout is selected
        if selectedWorkout == nil {
            manualTargetPower = Int(settings.userFTP * 0.6)
            manualTargetHR = settings.userLTHR - 20
        }
        
        recorderA.prepare()
        recorderB.prepare()
        
        isLoaded = true
        
        // Start the timer
        sessionTimer.start()
    }
    
    public func startRecording() {
        guard isLoaded, !isRecording else { return }
        
        let initialStepType = selectedWorkout?.steps.first?.type ?? .work
        lapManager.startNewLap(type: initialStepType)
        
        sessionStartTime = Date()
        isRecording = true
        isPaused = false
        sessionTimer.resume()
        
        recorderA.isRecording = true
        recorderB.isRecording = true
    }
    
    public func pauseWorkout() {
        guard isRecording else { return }
        isPaused = true
        recorderA.isRecording = false
        recorderB.isRecording = false
        sessionTimer.pause()
    }
    
    public func resumeWorkout() {
        guard isRecording else { return }
        isPaused = false
        recorderA.isRecording = true
        recorderB.isRecording = true
        sessionTimer.resume()
    }
    
    public func manualLap() {
        guard isRecording else { return }
        let currentStepType = currentWorkoutStep?.type ?? .work
        lapManager.startNewLap(type: currentStepType)
    }
    
    public func increaseDifficulty() {
        if selectedWorkout != nil {
            workoutDifficultyScale = min(2.0, workoutDifficultyScale + 0.01)
        } else {
            // Manual adjustment for Free Ride
            adjustManualTarget(amount: 5)
        }
    }
    
    public func decreaseDifficulty() {
        if selectedWorkout != nil {
            workoutDifficultyScale = max(0.5, workoutDifficultyScale - 0.01)
        } else {
            // Manual adjustment for Free Ride (backward compatibility with existing buttons)
            adjustManualTarget(amount: -5)
        }
    }
    
    public func adjustManualTarget(amount: Int) {
        if selectedWorkout != nil {
            if ergModeEnabled {
                // Adjust difficulty scale (amount is in percent points)
                let delta = Double(amount) / 100.0
                let newScale = min(2.0, max(0.5, workoutDifficultyScale + delta))
                // Round to 2 decimal places to avoid floating point drift
                workoutDifficultyScale = round(newScale * 100.0) / 100.0
            } else {
                // Adjust resistance level
                resistanceLevel = min(100.0, max(0.0, resistanceLevel + Double(amount)))
            }
        } else {
            switch freeRideControlMode {
            case .resistance:
                resistanceLevel = min(100.0, max(0.0, resistanceLevel + Double(amount)))
            case .power:
                manualTargetPower = max(0, manualTargetPower + amount)
            case .heartRate:
                manualTargetHR = max(40, manualTargetHR + amount)
            }
        }
    }
    
    public var canEnableErgMode: Bool {
        return trainerController.trainer?.supportsPowerControl ?? false
    }
    
    @MainActor
    private func tick() {
        let now = Date()
        let altitude = locationProvider.currentAltitude ?? settings.altitudeOverride
        
        // 1. Capture shared sensor data (like RR intervals) once
        let rrIntervals = recorderA.hrSource?.latestRRIntervals ?? []
        recorderA.hrSource?.latestRRIntervals.removeAll()
        
        // 2. Pulse both recorders (This captures data and auto-updates engines)
        let lapStart = lapManager.currentLap?.startTime
        recorderA.pulse(time: now, altitude: altitude, rrIntervals: rrIntervals, lapStartTime: lapStart)
        recorderB.pulse(time: now, altitude: altitude, rrIntervals: rrIntervals, lapStartTime: lapStart)
        
        guard isRecording else { return }
        guard !isPaused else { return }
        
        let totalElapsed = workoutElapsedTime
        lapManager.recordTick()
        
        if let workout = selectedWorkout {
            var accumulated: TimeInterval = 0
            var foundStep = false
            for (index, step) in workout.steps.enumerated() {
                if totalElapsed < accumulated + step.duration {
                    if currentStepIndex != index {
                        currentStepIndex = index
                        lapManager.startNewLap(type: step.type)
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
                if ergModeEnabled {
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
                        trainerController.setTargetPower(targetWatts)
                    }
                } else {
                    // Resistance Mode: Send manual resistance level
                    trainerController.setResistanceLevel(resistanceLevel)
                }
            } else {
                currentTargetPower = nil
                currentTargetHR = nil
            }
        } else {
            // No workout loaded: Manual Control
            let ftp = settings.userFTP
            
            switch freeRideControlMode {
            case .resistance:
                trainerController.setResistanceLevel(resistanceLevel)
                currentTargetPower = nil
                currentTargetHR = nil
            case .power:
                trainerController.setTargetPower(manualTargetPower)
                currentTargetPower = manualTargetPower
                currentTargetHR = nil
            case .heartRate:
                if let targetWatts = setpointCalculator.calculateManualHR(
                    targetHR: Double(manualTargetHR),
                    currentHR: recorderA.hrSource?.heartRate,
                    ftp: ftp
                ) {
                    trainerController.setTargetPower(targetWatts)
                }
                currentTargetHR = manualTargetHR
                currentTargetPower = nil
            }
        }
    }
    
    public func stopWorkout() {
        isRecording = false
        isLoaded = false
        isPaused = false
        isSaving = true
        
        recorderA.isRecording = false
        recorderB.isRecording = false
        
        setpointCalculator.reset()
        sessionTimer.stop()
        
        Task { @MainActor in
            defer { isSaving = false }
            var files: [URL] = []
            
            let workoutName = selectedWorkout?.name ?? "FreeRide"
            
            let metaA = ExportMetadata(
                workoutName: workoutName,
                powerMeterName: recorderA.powerSource?.name,
                hrmName: recorderA.hrSource?.name
            )
            
            let metaB = ExportMetadata(
                workoutName: workoutName,
                powerMeterName: recorderB.powerSource?.name,
                hrmName: recorderB.hrSource?.name
            )
            
            do {
                files.append(contentsOf: try recorderA.stop(metadata: metaA, laps: laps))
                files.append(contentsOf: try recorderB.stop(metadata: metaB, laps: laps))
                self.exportedFiles = files
            } catch let error as AppError {
                errorManager?.report(error)
            } catch {
                errorManager?.report(.unknown(error.localizedDescription))
            }
            
            if files.isEmpty && workoutElapsedTime < 10 {
                // This might already be caught by the recorder, but double checking
                errorManager?.report(.workout(.sessionTooShort))
            }
        }
    }
    
    public var currentWorkoutStep: WorkoutStep? {
        guard let workout = selectedWorkout, currentStepIndex < workout.steps.count else { return nil }
        return workout.steps[currentStepIndex]
    }
}
