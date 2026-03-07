import Foundation
import Combine

@MainActor
class WorkoutSessionManager: ObservableObject {
    @Published var hrDeviceAId: UUID?
    @Published var powerDeviceAId: UUID?
    
    @Published var hrDeviceBId: UUID?
    @Published var powerDeviceBId: UUID?
    
    @Published var isRecording = false
    @Published var sessionStartTime: Date?
    @Published var workoutElapsedTime: TimeInterval = 0
    
    @Published var activeProfile: ActivityProfile = .defaultProfile
    @Published var selectedWorkout: StructuredWorkout?
    
    @Published var currentStepIndex: Int = 0
    @Published var timeInStep: TimeInterval = 0
    
    @Published var laps: [Lap] = []
    
    public var recorderA = SessionRecorder()
    public var recorderB = SessionRecorder()
    
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
    
    func startWorkout(devices: [DiscoveredPeripheral]) {
        workoutElapsedTime = 0
        currentStepIndex = 0
        timeInStep = 0
        laps = []
        
        recorderA.hrDevice = devices.first { $0.id == hrDeviceAId }
        recorderA.powerDevice = devices.first { $0.id == powerDeviceAId }
        
        recorderB.hrDevice = devices.first { $0.id == hrDeviceBId }
        recorderB.powerDevice = devices.first { $0.id == powerDeviceBId }
        
        recorderA.prepare()
        recorderB.prepare()
        
        // Initial Lap
        let initialStepType = selectedWorkout?.steps.first?.type ?? .work
        startNewLap(type: initialStepType)
        
        sessionStartTime = Date()
        isRecording = true
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tick()
            }
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
        workoutElapsedTime += 1
        
        if let workout = selectedWorkout {
            timeInStep += 1
            let currentStep = workout.steps[currentStepIndex]
            if timeInStep >= currentStep.duration {
                if currentStepIndex < workout.steps.count - 1 {
                    currentStepIndex += 1
                    timeInStep = 0
                    // Auto-lap on step change
                    startNewLap(type: workout.steps[currentStepIndex].type)
                }
            }
        }
        
        let now = Date()
        let altitude = LocationManager.shared.currentAltitude ?? SettingsManager.shared.altitudeOverride
        
        recorderA.recordPoint(time: now, altitude: altitude)
        recorderB.recordPoint(time: now, altitude: altitude)
    }
    
    func stopWorkout() {
        isRecording = false
        timerCancellable?.cancel()
        timerCancellable = nil
        
        var files: [URL] = []
        if let urlA = recorderA.stop(label: "ProfileA") { files.append(urlA) }
        if let urlB = recorderB.stop(label: "ProfileB") { files.append(urlB) }
        
        if !files.isEmpty {
            exportedFiles = files
        }
    }
    
    var currentWorkoutStep: WorkoutStep? {
        guard let workout = selectedWorkout, currentStepIndex < workout.steps.count else { return nil }
        return workout.steps[currentStepIndex]
    }
}
