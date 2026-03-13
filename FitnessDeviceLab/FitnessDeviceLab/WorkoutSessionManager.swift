import Foundation
import Combine

@MainActor
class WorkoutSessionManager: ObservableObject {
    enum DataFieldMode: String, CaseIterable, Identifiable {
        case session = "Session"
        case lap = "Lap"
        var id: String { rawValue }
    }
    
    @Published var currentDataFieldMode: DataFieldMode = .session
    
    @Published var hrDeviceAId: UUID?
    @Published var powerDeviceAId: UUID?
    
    @Published var hrDeviceBId: UUID?
    @Published var powerDeviceBId: UUID?
    
    @Published var isRecording = false
    @Published var isLoaded = false
    @Published var isPaused = false
    @Published var isAutoPaused = false
    @Published var countdownToStart: Int? = nil
    
    @Published var sessionStartTime: Date?
    @Published var workoutElapsedTime: TimeInterval = 0
    
    @Published var activeProfile: ActivityProfile = .defaultProfile
    @Published var selectedWorkout: StructuredWorkout?
    @Published var ergModeEnabled = false
    @Published var resistanceLevel: Double = 40.0
    @Published var workoutDifficultyScale: Double = 1.0
    
    @Published var currentStepIndex: Int = 0
    @Published var timeInStep: TimeInterval = 0
    
    @Published var laps: [Lap] = []
    
    private var lastSentTargetPower: Int?
    private var lastSentResistanceLevel: Double?
    
    public var recorderA = SessionRecorder()
    public var recorderB = SessionRecorder()
    
    func increaseDifficulty() {
        workoutDifficultyScale = min(2.0, workoutDifficultyScale + 0.01)
    }
    
    func decreaseDifficulty() {
        workoutDifficultyScale = max(0.5, workoutDifficultyScale - 0.01)
    }
    
    var controlDevice: DiscoveredPeripheral? {
        if let devA = recorderA.powerDevice, devA.capabilities.contains(.fitnessMachine) {
            return devA
        }
        if let devB = recorderB.powerDevice, devB.capabilities.contains(.fitnessMachine) {
            return devB
        }
        return nil
    }
    
    var canEnableErgMode: Bool {
        controlDevice != nil
    }
    
    @Published public var engineA: DataFieldEngine
    @Published public var engineB: DataFieldEngine
    
    @Published var exportedFiles: [URL] = []
    
    private var timerCancellable: AnyCancellable?
    private var settingsCancellable: AnyCancellable?
    
    init() {
        let recA = SessionRecorder()
        let recB = SessionRecorder()
        self.recorderA = recA
        self.recorderB = recB
        self.engineA = DataFieldEngine(recorder: recA)
        self.engineB = DataFieldEngine(recorder: recB)
        
        // Observe settings changes
        settingsCancellable = SettingsManager.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.engineA.recalculate()
                    self?.engineB.recalculate()
                }
            }
    }
    
    func loadWorkout(devices: [DiscoveredPeripheral]) {
        workoutElapsedTime = 0
        currentStepIndex = 0
        timeInStep = 0
        laps = []
        isPaused = false
        isRecording = false
        countdownToStart = nil
        
        recorderA.hrDevice = devices.first { $0.id == hrDeviceAId }
        recorderA.powerDevice = devices.first { $0.id == powerDeviceAId }
        
        recorderB.hrDevice = devices.first { $0.id == hrDeviceBId }
        recorderB.powerDevice = devices.first { $0.id == powerDeviceBId }
        
        recorderA.prepare()
        recorderB.prepare()
        
        isLoaded = true
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tick()
            }
    }
    
    func startRecording() {
        guard isLoaded, !isRecording else { return }
        
        // Initial Lap
        let initialStepType = selectedWorkout?.steps.first?.type ?? .work
        startNewLap(type: initialStepType)
        
        sessionStartTime = Date()
        isRecording = true
        isPaused = false
        countdownToStart = nil
    }
    
    func pauseWorkout() {
        guard isRecording else { return }
        isPaused = true
        isAutoPaused = false
    }
    
    func resumeWorkout() {
        guard isRecording else { return }
        isPaused = false
        isAutoPaused = false
        // Adjust sessionStartTime to account for pause duration if needed, 
        // but currently we use Date() in recordPoint and calculate elapsed.
        // Actually, let's just make tick() not increment if paused.
    }
    
    func manualLap() {
        guard isRecording else { return }
        let currentStepType = currentWorkoutStep?.type ?? .work
        startNewLap(type: currentStepType)
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
    
    private func tick() {
        let now = Date()
        // Auto-start logic
        if isLoaded && !isRecording {
            let currentPower = recorderA.powerDevice?.cyclingPower ?? 0
            if currentPower > 0 {
                if let cd = countdownToStart {
                    if cd > 1 {
                        countdownToStart = cd - 1
                    } else {
                        startRecording()
                    }
                } else {
                    countdownToStart = 5
                }
            } else {
                countdownToStart = nil
            }
            return
        }
        
        guard isRecording else { return }
        
        // Auto-pause logic
        let currentPower = recorderA.powerDevice?.cyclingPower ?? 0
        if currentPower == 0 && !isPaused {
            isPaused = true
            isAutoPaused = true
        } else if isAutoPaused && currentPower > 0 {
            isPaused = false
            isAutoPaused = false
        }
        
        // Always record data points if recording, even if paused
        let altitude = LocationManager.shared.currentAltitude ?? SettingsManager.shared.altitudeOverride
        recorderA.recordPoint(time: now, altitude: altitude)
        recorderB.recordPoint(time: now, altitude: altitude)
        
        guard !isPaused else { return }
        
        // Increment elapsed time manually since we want to handle pauses
        workoutElapsedTime += 1.0
        let totalElapsed = workoutElapsedTime
        
        if let workout = selectedWorkout {
            // Recalculate current step and time in step based on totalElapsed
            var accumulated: TimeInterval = 0
            var foundStep = false
            for (index, step) in workout.steps.enumerated() {
                if totalElapsed < accumulated + step.duration {
                    if currentStepIndex != index {
                        // Auto-lap on step change
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
                // Workout finished! Auto-stop.
                stopWorkout()
                return
            }
            
            // ERG / Resistance Control (Only to one control device)
            if let trainer = controlDevice {
                if ergModeEnabled, let step = currentWorkoutStep {
                    let ftp = SettingsManager.shared.userFTP
                    let targetWatts = Int(round(step.targetPowerPercent * workoutDifficultyScale * ftp))
                    
                    if targetWatts != lastSentTargetPower {
                        trainer.setTargetPower(targetWatts)
                        lastSentTargetPower = targetWatts
                    }
                    lastSentResistanceLevel = nil
                } else {
                    // Manual Resistance Mode
                    if lastSentTargetPower != nil || lastSentResistanceLevel != resistanceLevel {
                        trainer.setResistanceLevel(resistanceLevel)
                        lastSentResistanceLevel = resistanceLevel
                        lastSentTargetPower = nil
                    }
                }
            } else {
                // No trainer connected, reset trackers
                lastSentTargetPower = nil
                lastSentResistanceLevel = nil
            }
        } else {
            // Not a structured workout
            if let trainer = controlDevice {
                if lastSentResistanceLevel != resistanceLevel {
                    trainer.setResistanceLevel(resistanceLevel)
                    lastSentResistanceLevel = resistanceLevel
                }
            }
        }
    }
    
    func stopWorkout() {
        isRecording = false
        isLoaded = false
        isPaused = false
        isAutoPaused = false
        timerCancellable?.cancel()
        timerCancellable = nil
        
        var files: [URL] = []
        files.append(contentsOf: recorderA.stop(label: "ProfileA", laps: laps))
        files.append(contentsOf: recorderB.stop(label: "ProfileB", laps: laps))
        
        if !files.isEmpty {
            exportedFiles = files
        }
    }
    
    var currentWorkoutStep: WorkoutStep? {
        guard let workout = selectedWorkout, currentStepIndex < workout.steps.count else { return nil }
        return workout.steps[currentStepIndex]
    }
}
