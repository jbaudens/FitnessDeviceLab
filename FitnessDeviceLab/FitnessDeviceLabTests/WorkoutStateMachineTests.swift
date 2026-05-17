import Testing
import Foundation
@testable import FitnessDeviceLab

struct WorkoutStateMachineTests {
    
    @Test func testEmptyWorkout() {
        let stateMachine = WorkoutStateMachine()
        let output = stateMachine.update(elapsedTime: 10, workout: nil)
        
        #expect(output.stepIndex == 0)
        #expect(output.timeInStep == 0)
        #expect(output.currentStep == nil)
        #expect(output.isFinished == false)
    }
    
    @Test func testWorkoutProgression() {
        let stateMachine = WorkoutStateMachine()
        let workout = StructuredWorkout(name: "Test", description: "Test", steps: [
            WorkoutStep(duration: 10, targetPowerPercent: 0.5), // 0-10s
            WorkoutStep(duration: 20, targetPowerPercent: 1.0)  // 10-30s
        ])
        
        // 1. Initial State
        var output = stateMachine.update(elapsedTime: 0, workout: workout)
        #expect(output.stepIndex == 0)
        #expect(output.timeInStep == 0)
        #expect(output.currentStep?.duration == 10)
        #expect(output.didTransitionStep == false)
        
        // 2. Mid-step 1
        output = stateMachine.update(elapsedTime: 5, workout: workout)
        #expect(output.stepIndex == 0)
        #expect(output.timeInStep == 5)
        #expect(output.didTransitionStep == false)
        
        // 3. Transition to Step 2
        output = stateMachine.update(elapsedTime: 10, workout: workout)
        #expect(output.stepIndex == 1)
        #expect(output.timeInStep == 0)
        #expect(output.didTransitionStep == true)
        #expect(output.currentStep?.duration == 20)
        
        // 4. Mid-step 2
        output = stateMachine.update(elapsedTime: 20, workout: workout)
        #expect(output.stepIndex == 1)
        #expect(output.timeInStep == 10)
        #expect(output.didTransitionStep == false)
        
        // 5. Finishing Workout
        output = stateMachine.update(elapsedTime: 30, workout: workout)
        #expect(output.isFinished == true)
        #expect(output.currentStep == nil)
    }
    
    @Test func testReset() {
        let stateMachine = WorkoutStateMachine()
        let workout = StructuredWorkout(name: "Test", description: "Test", steps: [
            WorkoutStep(duration: 10, targetPowerPercent: 0.5)
        ])
        
        _ = stateMachine.update(elapsedTime: 5, workout: workout)
        #expect(stateMachine.currentStepIndex == 0)
        #expect(stateMachine.timeInStep == 5)
        
        stateMachine.reset()
        #expect(stateMachine.currentStepIndex == 0)
        #expect(stateMachine.timeInStep == 0)
    }
}
