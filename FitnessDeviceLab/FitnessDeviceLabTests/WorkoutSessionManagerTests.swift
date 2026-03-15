import Testing
import Foundation
@testable import FitnessDeviceLab

@Observable
class MockSettingsProvider: SettingsProvider {
    var userFTP: Double = 200.0
    var maxHR: Int = 190
    var userLTHR: Int = 170
    var altitudeOverride: Double? = nil
    var userWeight: Double = 75.0
    var ftpAltitude: Double = 0.0
    var metricsSettings: MetricsSettings {
        MetricsSettings(userFTP: userFTP, userWeight: userWeight, ftpAltitude: ftpAltitude)
    }
}

class MockLocationProvider: LocationProvider {
    var currentAltitude: Double? = 100.0
}

@Observable
class MockTrainer: NSObject, SensorPeripheral, ResistanceControllable {
    let id = UUID()
    let name = "Mock Trainer"
    var isConnected = true
    var manufacturerName: String? = "Mock"
    var modelNumber: String? = "Mock-1"
    var capabilities: Set<DeviceCapability> = [.cyclingPower, .fitnessMachine]
    
    var heartRate: Int? = nil
    var cyclingPower: Int? = 0
    var cadence: Int? = 0
    var powerBalance: Double? = 50.0
    var latestRRIntervals: [Double] = []
    
    var lastSetTargetPower: Int?
    var lastSetResistanceLevel: Double?

    func setTargetPower(_ watts: Int) {
        lastSetTargetPower = watts
    }
    
    func setResistanceLevel(_ level: Double) {
        lastSetResistanceLevel = level
    }
}

@MainActor
struct WorkoutSessionManagerTests {

    func makeSUT() -> (WorkoutSessionManager, WorkoutTimer, MockSettingsProvider, MockLocationProvider) {
        let settings = MockSettingsProvider()
        let location = MockLocationProvider()
        let timer = WorkoutTimer()
        let sut = WorkoutSessionManager(settings: settings, locationProvider: location, workoutTimer: timer)
        return (sut, timer, settings, location)
    }

    @Test func testWorkoutStartAndStepTransitions() async throws {
        let (sut, timer, _, _) = makeSUT()
        let workout = StructuredWorkout(name: "Test", description: "Test", steps: [
            WorkoutStep(duration: 5, targetPowerPercent: 0.5), // 5s @ 100W
            WorkoutStep(duration: 5, targetPowerPercent: 1.0)  // 5s @ 200W
        ])
        sut.selectedWorkout = workout
        sut.ergModeEnabled = true
        
        let trainer = MockTrainer()
        let controllable = ControllableTrainer(peripheral: trainer)!
        
        sut.startWorkout(recA: sut.recorderA, recB: sut.recorderB, control: controllable)
        sut.startRecording()
        
        #expect(sut.isRecording == true)
        #expect(sut.currentStepIndex == 0)
        
        // Advance 3 seconds
        for _ in 0..<3 { timer.advanceOneSecond() }
        #expect(sut.workoutElapsedTime == 3.0)
        #expect(sut.currentStepIndex == 0)
        
        // Advance another 3 seconds (total 6) -> should be in step 2
        for _ in 0..<3 { timer.advanceOneSecond() }
        #expect(sut.workoutElapsedTime == 6.0)
        #expect(sut.currentStepIndex == 1)
        
        // Advance 5 more seconds (total 11) -> should be finished
        for _ in 0..<5 { timer.advanceOneSecond() }
        #expect(sut.isRecording == false)
        #expect(sut.isLoaded == false)
    }
    
    @Test func testPauseAndResume() async throws {
        let (sut, timer, _, _) = makeSUT()
        let workout = StructuredWorkout(name: "Test", description: "Test", steps: [
            WorkoutStep(duration: 60, targetPowerPercent: 0.5)
        ])
        sut.selectedWorkout = workout
        
        sut.startWorkout(recA: sut.recorderA, recB: sut.recorderB, control: nil)
        sut.startRecording()
        
        timer.advanceOneSecond()
        #expect(sut.workoutElapsedTime == 1.0)
        
        sut.pauseWorkout()
        #expect(sut.isPaused == true)
        
        // Advancing timer while paused should NOT increment workout time
        timer.advanceOneSecond()
        #expect(sut.workoutElapsedTime == 1.0)
        
        sut.resumeWorkout()
        #expect(sut.isPaused == false)
        
        timer.advanceOneSecond()
        #expect(sut.workoutElapsedTime == 2.0)
    }
    
    @Test func testManualLap() async throws {
        let (sut, timer, _, _) = makeSUT()
        let workout = StructuredWorkout(name: "Test", description: "Test", steps: [
            WorkoutStep(duration: 60, targetPowerPercent: 0.5)
        ])
        sut.selectedWorkout = workout
        sut.startWorkout(recA: sut.recorderA, recB: sut.recorderB, control: nil)
        sut.startRecording()
        
        #expect(sut.laps.count == 1)
        
        timer.advanceOneSecond()
        sut.manualLap()
        
        #expect(sut.laps.count == 2)
        #expect(sut.laps[0].endTime != nil)
    }
}
