import Foundation

/// A core utility for shared cycling power calculations (NP, IF, TSS).
public enum PowerMath {
    
    /// Calculates Normalized Power (NP) from a sequence of 30-second rolling averages.
    /// NP is the 4th root of the average of the 4th powers of these rolling averages.
    nonisolated public static func calculateNP(from30sRollingAverages rollingAverages: [Double]) -> Double? {
        guard !rollingAverages.isEmpty else { return nil }
        let sum4 = rollingAverages.reduce(0.0) { $0 + pow($1, 4) }
        return pow(sum4 / Double(rollingAverages.count), 0.25)
    }
    
    /// Calculates Intensity Factor (IF).
    nonisolated public static func calculateIF(np: Double, ftp: Double) -> Double {
        guard ftp > 0 else { return 0 }
        return np / ftp
    }
    
    /// Calculates Training Stress Score (TSS).
    nonisolated public static func calculateTSS(durationSeconds: Double, np: Double, ifValue: Double, ftp: Double) -> Double {
        guard ftp > 0 else { return 0 }
        return (durationSeconds * np * ifValue) / (ftp * 36.0)
    }
    
    /// Calculates Normalized Power (NP) from raw second-by-second samples.
    nonisolated public static func calculateNP(fromSamples samples: [Double]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let rolling = generate30sRollingAverages(from: samples)
        return calculateNP(from30sRollingAverages: rolling)
    }

    /// Generates 30-second rolling averages from a stream of 1-second samples.
    nonisolated public static func generate30sRollingAverages(from samples: [Double]) -> [Double] {
        guard !samples.isEmpty else { return [] }
        var rollingAverages = [Double]()
        var currentSum = 0.0
        
        for i in 0..<samples.count {
            currentSum += samples[i]
            if i >= 30 {
                currentSum -= samples[i - 30]
            }
            let count = Double(min(i + 1, 30))
            rollingAverages.append(currentSum / count)
        }
        return rollingAverages
    }
}
