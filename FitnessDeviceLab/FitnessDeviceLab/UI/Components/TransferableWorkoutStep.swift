import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct TransferableWorkoutStep: Codable, Transferable, Sendable {
    let steps: [WorkoutStep]
    
    // Helper for single step convenience
    var step: WorkoutStep? { steps.first }
    
    init(step: WorkoutStep) {
        self.steps = [step]
    }
    
    init(steps: [WorkoutStep]) {
        self.steps = steps
    }
    
    static var transferRepresentation: some TransferRepresentation {
        // Use standard 'data' type to avoid macOS registration requirements
        CodableRepresentation(contentType: .data)
    }
}
