import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct TransferableWorkoutStep: Codable, Transferable, Sendable {
    let step: WorkoutStep
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .workoutStep)
    }
}

extension UTType {
    static var workoutStep: UTType {
        UTType(exportedAs: "com.fitnessdevicelab.workoutstep")
    }
}
