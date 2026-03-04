import Foundation
import SwiftUI

public enum WorkoutZone: Int, Codable, CaseIterable, Identifiable {
    case z1 = 1 // Active Recovery
    case z2 = 2 // Endurance
    case z3 = 3 // Tempo
    case z4 = 4 // Threshold
    case z5 = 5 // VO2 Max
    case z6 = 6 // Anaerobic Capacity
    case z7 = 7 // Neuromuscular Power
    
    public var id: Int { rawValue }
    
    public var name: String {
        switch self {
        case .z1: return "Recovery"
        case .z2: return "Endurance"
        case .z3: return "Tempo"
        case .z4: return "Threshold"
        case .z5: return "VO2 Max"
        case .z6: return "Anaerobic"
        case .z7: return "Sprints"
        }
    }
    
    public var color: Color {
        switch self {
        case .z1: return .gray
        case .z2: return .blue
        case .z3: return .green
        case .z4: return .yellow
        case .z5: return .orange
        case .z6: return .red
        case .z7: return .purple
        }
    }
    
    // Determine zone based on intensity (% FTP)
    public static func forIntensity(_ intensity: Double) -> WorkoutZone {
        if intensity < 0.55 { return .z1 }
        if intensity < 0.75 { return .z2 }
        if intensity < 0.90 { return .z3 }
        if intensity < 1.05 { return .z4 }
        if intensity < 1.20 { return .z5 }
        if intensity < 1.50 { return .z6 }
        return .z7
    }
}

public enum WorkoutStepType: String, Codable {
    case warmup = "Warmup"
    case work = "Work"
    case recovery = "Recovery"
    case cooldown = "Cooldown"
}

public struct WorkoutStep: Identifiable, Codable, Hashable {
    public let id: UUID
    public let duration: TimeInterval // seconds
    public let targetPowerPercent: Double // % of FTP
    public let targetCadence: Int?
    public let type: WorkoutStepType
    
    public init(id: UUID = UUID(), duration: TimeInterval, targetPowerPercent: Double, type: WorkoutStepType = .work, targetCadence: Int? = nil) {
        self.id = id
        self.duration = duration
        self.targetPowerPercent = targetPowerPercent
        self.type = type
        self.targetCadence = targetCadence
    }
}

public struct StructuredWorkout: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name: String
    public let description: String
    public let steps: [WorkoutStep]
    
    public init(id: UUID = UUID(), name: String, description: String, steps: [WorkoutStep]) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
    }
    
    public var totalDuration: TimeInterval {
        steps.reduce(0) { $0 + $1.duration }
    }
    
    public var averageIntensity: Double {
        guard !steps.isEmpty else { return 0 }
        let totalWork = steps.reduce(0.0) { $0 + ($1.targetPowerPercent * $1.duration) }
        return totalWork / totalDuration
    }
    
    public var primaryZone: WorkoutZone {
        // Find the zone with the most duration in 'work' steps
        let workSteps = steps.filter { $0.type == .work }
        if workSteps.isEmpty { return .z1 }
        
        let intensity = workSteps.reduce(0.0) { $0 + ($1.targetPowerPercent * $1.duration) } / workSteps.reduce(0) { $0 + $1.duration }
        return WorkoutZone.forIntensity(intensity)
    }
}
