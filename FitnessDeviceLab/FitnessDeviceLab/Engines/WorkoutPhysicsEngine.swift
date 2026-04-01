import Foundation

/// A stateless engine for calculating workout-wide metrics like Normalized Power (NP),
/// Intensity Factor (IF), Training Stress Score (TSS), and zone distributions.
public struct WorkoutPhysicsEngine {
    
    /// Calculates the average intensity of a workout based on its steps.
    public static func calculateAverageIntensity(for steps: [WorkoutStep]) -> Double {
        guard !steps.isEmpty else { return 0 }
        let powerSteps = steps.filter { $0.targetPowerPercent != nil }
        guard !powerSteps.isEmpty else { return 0 }
        
        let totalWork = powerSteps.reduce(0.0) { $0 + ((($1.targetPowerPercent! + $1.endTargetPowerPercent!) / 2.0) * $1.duration) }
        let powerDuration = powerSteps.reduce(0.0) { $0 + $1.duration }
        return totalWork / powerDuration
    }
    
    /// Calculates the Intensity Factor (IF) using a Normalized Power (NP) proxy approach.
    public static func calculateIntensityFactor(for steps: [WorkoutStep]) -> Double {
        guard !steps.isEmpty else { return 0 }
        let samples = generateIntensitySamples(for: steps)
        guard !samples.isEmpty else { return 0 }
        
        let np = PowerMath.calculateNP(fromSamples: samples) ?? 0
        return PowerMath.calculateIF(np: np, ftp: 1.0) // IF is NP relative to FTP (1.0 in this proxy case)
    }
    
    /// Calculates the Training Stress Score (TSS) for a workout.
    public static func calculateTSS(for steps: [WorkoutStep]) -> Double {
        let durationSeconds = steps.reduce(0.0) { $0 + $1.duration }
        let samples = generateIntensitySamples(for: steps)
        guard !samples.isEmpty else { return 0 }
        
        let np = PowerMath.calculateNP(fromSamples: samples) ?? 0
        let ifValue = PowerMath.calculateIF(np: np, ftp: 1.0)
        
        return PowerMath.calculateTSS(durationSeconds: durationSeconds, np: np, ifValue: ifValue, ftp: 1.0)
    }
    
    /// Determines the primary workout zone based on the intensity of 'work' steps.
    /// If no 'work' steps are found, falls back to the workout's overall Intensity Factor (IF).
    public static func determinePrimaryZone(for steps: [WorkoutStep]) -> WorkoutZone {
        let workSteps = steps.filter { $0.type == .work }
        let targetSteps = workSteps.isEmpty ? steps : workSteps
        
        let ifValue = calculateIntensityFactor(for: targetSteps)
        
        // Determine if we should use Power or HR thresholds for classification
        let hrCount = targetSteps.filter { $0.targetHeartRatePercent != nil }.count
        let powerCount = targetSteps.filter { $0.targetPowerPercent != nil }.count
        
        if hrCount > powerCount {
            return WorkoutZone.forHRIntensity(ifValue)
        } else {
            return WorkoutZone.forIntensity(ifValue)
        }
    }
    
    // MARK: - Private Helpers
    
    private static func generateIntensitySamples(for steps: [WorkoutStep]) -> [Double] {
        var samples = [Double]()
        for step in steps {
            let count = Int(step.duration)
            if let start = step.targetPowerPercent {
                for i in 0..<count {
                    samples.append(step.powerAt(time: Double(i)) ?? start)
                }
            } else if let hr = step.targetHeartRatePercent {
                for _ in 0..<count {
                    samples.append(hr) // Use HR % as a proxy for Power %
                }
            }
        }
        return samples
    }
}
