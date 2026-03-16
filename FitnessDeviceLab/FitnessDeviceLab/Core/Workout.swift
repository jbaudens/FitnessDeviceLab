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
    
    // Joe Friel HR Zones (% of LTHR)
    public static func forHRIntensity(_ hrPercent: Double) -> WorkoutZone {
        if hrPercent < 0.82 { return .z1 } // Recovery
        if hrPercent < 0.89 { return .z2 } // Aerobic
        if hrPercent < 0.94 { return .z3 } // Tempo
        if hrPercent < 1.00 { return .z4 } // Sub-Threshold
        if hrPercent < 1.03 { return .z5 } // Super-Threshold
        if hrPercent < 1.06 { return .z6 } // Aerobic Capacity
        return .z7 // Anaerobic
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
    public let targetPowerPercent: Double? // % of FTP (start of step)
    public let endTargetPowerPercent: Double? // % of FTP (end of step)
    public let targetHeartRatePercent: Double? // % of LTHR
    public let targetCadence: Int?
    public let type: WorkoutStepType
    
    public init(id: UUID = UUID(), duration: TimeInterval, targetPowerPercent: Double? = nil, endTargetPowerPercent: Double? = nil, targetHeartRatePercent: Double? = nil, type: WorkoutStepType = .work, targetCadence: Int? = nil) {
        self.id = id
        self.duration = duration
        self.targetPowerPercent = targetPowerPercent
        self.endTargetPowerPercent = endTargetPowerPercent ?? targetPowerPercent
        self.targetHeartRatePercent = targetHeartRatePercent
        self.type = type
        self.targetCadence = targetCadence
    }
    
    public var isRamp: Bool {
        guard let start = targetPowerPercent, let end = endTargetPowerPercent else { return false }
        return abs(end - start) > 0.001
    }
    
    public func powerAt(time: TimeInterval) -> Double? {
        guard let start = targetPowerPercent, let end = endTargetPowerPercent else { return nil }
        guard duration > 0 else { return start }
        let progress = min(1.0, max(0.0, time / duration))
        return start + (end - start) * progress
    }
    
    public var currentZone: WorkoutZone {
        if let hr = targetHeartRatePercent {
            return WorkoutZone.forHRIntensity(hr)
        }
        let start = targetPowerPercent ?? 0
        let end = endTargetPowerPercent ?? start
        return WorkoutZone.forIntensity((start + end) / 2.0)
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
    
    public enum WorkoutMetric: String {
        case power = "Power"
        case heartRate = "Heart Rate"
    }
    
    public var primaryMetric: WorkoutMetric {
        let hrSteps = steps.filter { $0.targetHeartRatePercent != nil }.count
        let powerSteps = steps.filter { $0.targetPowerPercent != nil }.count
        return hrSteps > powerSteps ? .heartRate : .power
    }
    
    public var averageIntensity: Double {
        WorkoutPhysicsEngine.calculateAverageIntensity(for: steps)
    }
    
    public var intensityFactor: Double {
        WorkoutPhysicsEngine.calculateIntensityFactor(for: steps)
    }
    
    public var tss: Double {
        WorkoutPhysicsEngine.calculateTSS(for: steps)
    }
    
    public var primaryZone: WorkoutZone {
        WorkoutPhysicsEngine.determinePrimaryZone(for: steps)
    }
}
