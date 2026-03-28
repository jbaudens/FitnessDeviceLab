import Testing
import Foundation
@testable import FitnessDeviceLab

@MainActor
struct WorkoutSessionManagerTests {

    func makeSUT() -> (WorkoutSessionManager, SessionTimer, MockSettingsProvider, MockLocationProvider) {
        let settings = MockSettingsProvider()
        let location = MockLocationProvider()
        let timer = SessionTimer()
        let error = ErrorManager()
        let recorderA = SessionRecorder(settings: settings)
        let recorderB = SessionRecorder(settings: settings)
        let sut = WorkoutSessionManager(
            settings: settings, 
            locationProvider: location, 
            sessionTimer: timer,
            recorderA: recorderA,
            recorderB: recorderB,
            errorManager: error
        )
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
    
    @Test func testFreeRideManualControl() async throws {
        let (sut, timer, _, _) = makeSUT()
        
        let mockTrainer = MockTrainer()
        let controllable = ControllableTrainer(peripheral: mockTrainer)!
        
        // Setup Free Ride (no workout selected)
        sut.selectedWorkout = nil
        sut.startWorkout(recA: sut.recorderA, recB: sut.recorderB, control: controllable)
        sut.startRecording()
        
        // 1. Test Resistance Mode (Default)
        sut.freeRideControlMode = .resistance
        sut.resistanceLevel = 50.0
        timer.advanceOneSecond()
        
        // We need to wait for the next tick to process the trainer commands
        // In this mock setup, advanceOneSecond calls the tick immediately.
        #expect(mockTrainer.lastSetResistanceLevel == 50.0)
        
        // 2. Test Power ERG Mode
        sut.freeRideControlMode = .power
        sut.manualTargetPower = 200
        timer.advanceOneSecond()
        #expect(mockTrainer.lastSetTargetPower == 200)
        #expect(sut.currentTargetPower == 200)
        
        // 3. Test Heart Rate ERG Mode
        sut.freeRideControlMode = .heartRate
        sut.manualTargetHR = 140
        // Set current HR to 130 to trigger an adjustment
        mockTrainer.heartRate = 130
        
        // Link trainer to recorderA so tick() sees the HR
        sut.recorderA.hrSource = HeartRateSensor(peripheral: mockTrainer)
        
        timer.advanceOneSecond()
        #expect(mockTrainer.lastSetTargetPower != nil)
        #expect(sut.currentTargetHR == 140)
    }
    
    @Test func testManualTargetAdjustments() async throws {
        let (sut, _, _, _) = makeSUT()
        
        // 1. Free Ride
        sut.selectedWorkout = nil
        sut.freeRideControlMode = .power
        sut.manualTargetPower = 200
        
        sut.adjustManualTarget(amount: 1)
        #expect(sut.manualTargetPower == 201)
        
        // 2. Structured Workout ERG (Difficulty Scale)
        sut.selectedWorkout = StructuredWorkout(name: "Test", description: "Test Description", steps: [WorkoutStep(duration: 60, targetPowerPercent: 0.5)])
        sut.ergModeEnabled = true
        sut.workoutDifficultyScale = 1.0
        
        sut.adjustManualTarget(amount: 5) // +5%
        #expect(sut.workoutDifficultyScale == 1.05)
        
        sut.adjustManualTarget(amount: -10) // -10%
        #expect(sut.workoutDifficultyScale == 0.95)
        
        // 3. Structured Workout Resistance
        sut.ergModeEnabled = false
        sut.resistanceLevel = 50.0
        sut.adjustManualTarget(amount: 5)
        #expect(sut.resistanceLevel == 55.0)
    }
}
