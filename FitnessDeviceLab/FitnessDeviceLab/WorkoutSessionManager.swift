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
        exportedFiles = []
        
        recorderA.hrDevice = devices.first { $0.id == hrDeviceAId }
        recorderA.powerDevice = devices.first { $0.id == powerDeviceAId }
        
        recorderB.hrDevice = devices.first { $0.id == hrDeviceBId }
        recorderB.powerDevice = devices.first { $0.id == powerDeviceBId }
        
        recorderA.prepare()
        recorderB.prepare()
        
        recorderA.isRecording = false
        recorderB.isRecording = false
        
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
        
        recorderA.isRecording = true
        recorderB.isRecording = true
    }
    
    func pauseWorkout() {
        guard isRecording else { return }
        isPaused = true
        recorderA.isRecording = false
        recorderB.isRecording = false
    }
    
    func resumeWorkout() {
        guard isRecording else { return }
        isPaused = false
        recorderA.isRecording = true
        recorderB.isRecording = true
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
        let altitude = LocationManager.shared.currentAltitude ?? SettingsManager.shared.altitudeOverride
        
        // Always record current point for live data display, but recorder handles whether to append to trackpoints
        recorderA.recordPoint(time: now, altitude: altitude)
        recorderB.recordPoint(time: now, altitude: altitude)
        
        // Ensure data fields update
        engineA.recalculate()
        engineB.recalculate()
        
        guard isRecording else { return }
        
        guard !isPaused else { return }
        
        // Increment elapsed time
        workoutElapsedTime += 1.0
        let totalElapsed = workoutElapsedTime
        
        if !laps.isEmpty {
            laps[laps.count - 1].activeDuration += 1.0
        }
        
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
                // Workout finished structured steps, keep recording but stop updating steps
                currentStepIndex = workout.steps.count - 1
                timeInStep = workout.steps.last!.duration
            }
            
            // ERG / Resistance Control
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
        
        recorderA.isRecording = false
        recorderB.isRecording = false
        
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
