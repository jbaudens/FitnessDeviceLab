import Foundation

public struct StateMachineOutput {
    public let stepIndex: Int
    public let timeInStep: TimeInterval
    public let currentStep: WorkoutStep?
    public let nextStep: WorkoutStep?
    public let isFinished: Bool
    public let didTransitionStep: Bool
}

public class WorkoutStateMachine {
    public private(set) var currentStepIndex: Int = 0
    public private(set) var timeInStep: TimeInterval = 0
    
    public init() {}
    
    public func update(elapsedTime: TimeInterval, workout: StructuredWorkout?) -> StateMachineOutput {
        guard let workout = workout, !workout.steps.isEmpty else {
            return StateMachineOutput(stepIndex: 0, timeInStep: 0, currentStep: nil, nextStep: nil, isFinished: false, didTransitionStep: false)
        }
        
        var accumulated: TimeInterval = 0
        var foundIndex: Int?
        var didTransition = false
        
        for (index, step) in workout.steps.enumerated() {
            if elapsedTime < accumulated + step.duration {
                foundIndex = index
                timeInStep = elapsedTime - accumulated
                break
            }
            accumulated += step.duration
        }
        
        if let index = foundIndex {
            if index != currentStepIndex {
                didTransition = true
                currentStepIndex = index
            }
            let currentStep = workout.steps[index]
            let nextStep = (index < workout.steps.count - 1) ? workout.steps[index + 1] : nil
            return StateMachineOutput(
                stepIndex: index,
                timeInStep: timeInStep,
                currentStep: currentStep,
                nextStep: nextStep,
                isFinished: false,
                didTransitionStep: didTransition
            )
        } else {
            // Finished
            return StateMachineOutput(
                stepIndex: workout.steps.count - 1,
                timeInStep: workout.steps.last?.duration ?? 0,
                currentStep: nil,
                nextStep: nil,
                isFinished: true,
                didTransitionStep: false
            )
        }
    }
    
    public func reset() {
        currentStepIndex = 0
        timeInStep = 0
    }
}
