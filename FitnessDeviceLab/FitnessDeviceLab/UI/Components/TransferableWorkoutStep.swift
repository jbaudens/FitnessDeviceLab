import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct TransferableWorkoutStep: Codable, Transferable, Sendable {
    let step: WorkoutStep
    
    static var transferRepresentation: some TransferRepresentation {
        // Use a more standard data type for reliability
        DataRepresentation(contentType: .data) { item in
            try JSONEncoder().encode(item.step)
        } importing: { data in
            let step = try JSONDecoder().decode(WorkoutStep.self, from: data)
            return TransferableWorkoutStep(step: step)
        }
    }
}

extension UTType {
    static var workoutStep: UTType {
        UTType(exportedAs: "com.fitnessdevicelab.workoutstep")
    }
}
