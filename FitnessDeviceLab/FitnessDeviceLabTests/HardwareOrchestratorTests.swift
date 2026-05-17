import Testing
import Foundation
@testable import FitnessDeviceLab

@MainActor
struct HardwareOrchestratorTests {
    
    @Test func testStructuredWorkoutPowerStep() async throws {
        let trainer = MockTrainer()
        let controllable = ControllableTrainer(peripheral: trainer)!
        let controller = TrainerController(trainer: controllable)
        let calculator = TrainerSetpointCalculator()
        let settings = MockSettingsProvider()
        settings.userFTP = 200.0
        
        let orchestrator = HardwareOrchestrator(
            trainerController: controller,
            setpointCalculator: calculator,
            settings: settings
        )
        
        let step = WorkoutStep(duration: 60, targetPowerPercent: 0.5) // 100W
        
        let result = orchestrator.update(
            selectedWorkout: nil as StructuredWorkout?,
            freeRideMode: .resistance,
            manualTargetPower: 150,
            manualTargetHR: 140,
            resistanceLevel: 25.0,
            ergModeEnabled: true,
            workoutStep: step,
            nextStep: nil as WorkoutStep?,
            timeInStep: 10,
            isFinished: false,
            difficultyScale: 1.0,
            currentHR: nil as Int?
        )
        
        #expect(result.power == 100)
        #expect(trainer.lastSetTargetPower == 100)
    }
    
    @Test func testFreeRideResistanceMode() async throws {
        let trainer = MockTrainer()
        let controllable = ControllableTrainer(peripheral: trainer)!
        let controller = TrainerController(trainer: controllable)
        let calculator = TrainerSetpointCalculator()
        let settings = MockSettingsProvider()
        
        let orchestrator = HardwareOrchestrator(
            trainerController: controller,
            setpointCalculator: calculator,
            settings: settings
        )
        
        let result = orchestrator.update(
            selectedWorkout: nil as StructuredWorkout?,
            freeRideMode: .resistance,
            manualTargetPower: 150,
            manualTargetHR: 140,
            resistanceLevel: 30.0,
            ergModeEnabled: false,
            workoutStep: nil as WorkoutStep?,
            nextStep: nil as WorkoutStep?,
            timeInStep: 0,
            isFinished: false,
            difficultyScale: 1.0,
            currentHR: nil as Int?
        )
        
        #expect(result.power == nil)
        #expect(trainer.lastSetResistanceLevel == 30.0)
    }

    @Test func testFreeRidePowerMode() async throws {
        let trainer = MockTrainer()
        let controllable = ControllableTrainer(peripheral: trainer)!
        let controller = TrainerController(trainer: controllable)
        let calculator = TrainerSetpointCalculator()
        let settings = MockSettingsProvider()
        
        let orchestrator = HardwareOrchestrator(
            trainerController: controller,
            setpointCalculator: calculator,
            settings: settings
        )
        
        let result = orchestrator.update(
            selectedWorkout: nil as StructuredWorkout?,
            freeRideMode: .power,
            manualTargetPower: 220,
            manualTargetHR: 140,
            resistanceLevel: 30.0,
            ergModeEnabled: false,
            workoutStep: nil as WorkoutStep?,
            nextStep: nil as WorkoutStep?,
            timeInStep: 0,
            isFinished: false,
            difficultyScale: 1.0,
            currentHR: nil as Int?
        )
        
        #expect(result.power == 220)
        #expect(trainer.lastSetTargetPower == 220)
    }
}
