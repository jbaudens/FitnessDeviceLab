import Foundation
import Observation
import SwiftUI

@Observable
public class WorkoutEditorViewModel {
    public var name: String
    public var description: String
    public var steps: [WorkoutStep]
    public var selectedStepID: UUID?
    public var selectedStepIDs: Set<UUID> = []
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
    
    public var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !steps.isEmpty && 
        totalDuration > 0
    }
    
    public func save() {
        guard canSave else { return }
        
        let workout = draftWorkout
        if isNewWorkout {
            repository.add(workout)
        } else {
            repository.update(workout)
        }
    }
    
    public func deleteWorkout() {
        guard !isNewWorkout else { return }
        repository.delete(draftWorkout)
    }
    
    public func addStep(_ step: WorkoutStep) {
        steps.append(step)
        selectedStepID = step.id
        selectedStepIDs = [step.id]
    }
    
    public func duplicateStep(id: UUID) {
        duplicateSteps(ids: [id])
    }
    
    public func duplicateSteps(ids: Set<UUID>) {
        let sortedIndices = ids.compactMap { id in steps.firstIndex(where: { $0.id == id }) }.sorted()
        guard !sortedIndices.isEmpty else { return }
        
        let originalSteps = sortedIndices.map { steps[$0] }
        let copies = originalSteps.map { original in
            WorkoutStep(
                duration: original.duration,
                targetPowerPercent: original.targetPowerPercent,
                endTargetPowerPercent: original.endTargetPowerPercent,
                targetHeartRatePercent: original.targetHeartRatePercent,
                type: original.type,
                targetCadence: original.targetCadence
            )
        }
        
        let insertAt = sortedIndices.last! + 1
        steps.insert(contentsOf: copies, at: insertAt)
        
        selectedStepIDs = Set(copies.map { $0.id })
        selectedStepID = copies.first?.id
    }
    
    public func deleteStep(id: UUID) {
        deleteSteps(ids: [id])
    }
    
    public func deleteSteps(ids: Set<UUID>) {
        steps.removeAll(where: { ids.contains($0.id) })
        if ids.contains(selectedStepID ?? UUID()) {
            selectedStepID = nil
        }
        selectedStepIDs.subtract(ids)
    }
}
