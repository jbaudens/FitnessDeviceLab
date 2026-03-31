import Foundation
import Observation
import SwiftUI

@Observable
public class WorkoutEditorViewModel {
    public var name: String
    public var description: String
    public var steps: [WorkoutStep]
    public var selectedStepID: UUID?
    public let id: UUID
    
    private let repository: WorkoutRepository
    public let isNewWorkout: Bool
    
    public init(workout: StructuredWorkout? = nil, repository: WorkoutRepository = .shared) {
        self.repository = repository
        if let workout = workout {
            self.id = workout.id
            self.name = workout.name
            self.description = workout.description
            self.steps = workout.steps
            self.isNewWorkout = false
        } else {
            self.id = UUID()
            self.name = "New Workout"
            self.description = ""
            self.steps = []
            self.isNewWorkout = true
        }
        self.selectedStepID = nil
    }
    
    public var draftWorkout: StructuredWorkout {
        StructuredWorkout(id: id, name: name, description: description, steps: steps)
    }
    
    public var totalDuration: TimeInterval {
        draftWorkout.totalDuration
    }
    
    public var intensityFactor: Double {
        draftWorkout.intensityFactor
    }
    
    public var tss: Double {
        draftWorkout.tss
    }
    
    public func save() {
        let workout = draftWorkout
        if isNewWorkout {
            repository.add(workout)
        } else {
            repository.update(workout)
        }
    }
    
    public func duplicateStep(id: UUID) {
        guard let index = steps.firstIndex(where: { $0.id == id }) else { return }
        let original = steps[index]
        let copy = WorkoutStep(
            duration: original.duration,
            targetPowerPercent: original.targetPowerPercent,
            endTargetPowerPercent: original.endTargetPowerPercent,
            targetHeartRatePercent: original.targetHeartRatePercent,
            type: original.type,
            targetCadence: original.targetCadence
        )
        steps.insert(copy, at: index + 1)
        selectedStepID = copy.id
    }
    
    public func deleteStep(id: UUID) {
        guard let index = steps.firstIndex(where: { $0.id == id }) else { return }
        steps.remove(at: index)
        if selectedStepID == id {
            selectedStepID = nil
        }
    }
}
