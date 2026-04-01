import Foundation

nonisolated public enum HRVMeasurementMode {
    case resting
    case biofeedback
    case exercise
}

nonisolated public struct HRVConfig {
    public var windowSizeSeconds: Int
    public var stepSizeSeconds: Int
    public var artifactCorrectionThreshold: Double
    public var mode: HRVMeasurementMode
    
    public static let hrvLoggerExercise = HRVConfig(
        windowSizeSeconds: 120, // 2 minutes
        stepSizeSeconds: 5,
        artifactCorrectionThreshold: 0.15, // Tightened for exercise
        mode: .exercise
    )
    
    public static let hrvLoggerResting = HRVConfig(
        windowSizeSeconds: 300, // 5 minutes for gold standard resting
        stepSizeSeconds: 30,
        artifactCorrectionThreshold: 0.20,
        mode: .resting
    )
}

nonisolated public struct HRVMetrics {
    public var avnn: Double?
    public var sdnn: Double?
    public var rmssd: Double?
    public var pnn50: Double?
    public var dfaAlpha1: Double?
    
    public init(avnn: Double? = nil, sdnn: Double? = nil, rmssd: Double? = nil, pnn50: Double? = nil, dfaAlpha1: Double? = nil) {
        self.avnn = avnn
        self.sdnn = sdnn
        self.rmssd = rmssd
        self.pnn50 = pnn50
        self.dfaAlpha1 = dfaAlpha1
    }
}

nonisolated public struct Beat: Sendable {
    public let time: Date
    public let rr: Double
    
    public init(time: Date, rr: Double) {
        self.time = time
        self.rr = rr
    }
}

public struct HRVEngine {
    
    nonisolated public static func calculateMetrics(beats: [Beat], config: HRVConfig = .hrvLoggerExercise) -> HRVMetrics {
        // 1. Wall-clock time-based windowing
        guard let latestTime = beats.last?.time else { return HRVMetrics() }
        let startTime = latestTime.addingTimeInterval(-Double(config.windowSizeSeconds))
        
        let windowedBeats = beats.filter { $0.time >= startTime }
        let rawRRIntervals = windowedBeats.map { $0.rr }
        
        // 2. Artifact Correction (Moving Median Filter + Threshold)
        let correctedRR = correctArtifacts(rawRRIntervals, threshold: config.artifactCorrectionThreshold)
        
        let N = correctedRR.count
        // For exercise, we need at least 60 samples for DFA Alpha 1 to be somewhat stable
        let minIntervals = config.mode == .exercise ? 60 : 150
        guard N >= minIntervals else { return HRVMetrics() }
        
        // 3. Time Domain Metrics
        let meanRR = correctedRR.reduce(0, +) / Double(N)
        let variance = correctedRR.map { pow($0 - meanRR, 2) }.reduce(0, +) / Double(N - 1)
        let sdnn = sqrt(variance)
        
        var diffSqSum: Double = 0
        var nn50Count: Int = 0
        
        for i in 1..<N {
            let diff = abs(correctedRR[i] - correctedRR[i-1])
            diffSqSum += (diff * diff)
            if diff > 0.05 { // 50 ms
                nn50Count += 1
            }
        }
        
        let rmssd = sqrt(diffSqSum / Double(N - 1))
        let pnn50 = (Double(nn50Count) / Double(N - 1)) * 100.0
        
        // 4. DFA Alpha 1 with Overlapping Windows and Improved Regression
        let dfa = calculateDFAAlpha1(rrIntervals: correctedRR)
        
        return HRVMetrics(
            avnn: meanRR * 1000.0,
            sdnn: sdnn * 1000.0,
            rmssd: rmssd * 1000.0,
            pnn50: pnn50,
            dfaAlpha1: dfa
        )
    }
    
    nonisolated private static func correctArtifacts(_ rr: [Double], threshold: Double) -> [Double] {
        guard rr.count > 5 else { return rr }
        var result = [Double]()
        
        for i in 0..<rr.count {
            let val = rr[i]
            // Basic physiological range check (300ms to 2000ms -> 30bpm to 200bpm)
            if val < 0.3 || val > 2.0 { continue }
            
            // Moving median check (window of 5)
            let start = max(0, i - 2)
            let end = min(rr.count, i + 3)
            let neighbors = Array(rr[start..<end]).sorted()
            let median = neighbors[neighbors.count / 2]
            
            if abs(val - median) / median < threshold {
                result.append(val)
            }
        }
        return result
    }
    
    nonisolated private static func calculateDFAAlpha1(rrIntervals: [Double]) -> Double? {
        let N = rrIntervals.count
        let meanRR = rrIntervals.reduce(0, +) / Double(N)
        
        // Integrated series y(k)
        var y = [Double]()
        y.reserveCapacity(N)
        var sum: Double = 0
        for rr in rrIntervals {
            sum += (rr - meanRR)
            y.append(sum)
        }
        
        // Short-term Alpha 1 (standard range 4 to 16)
        let boxSizes = [4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16]
        var logN = [Double]()
        var logF = [Double]()
        
        for n in boxSizes {
            // Ensure we have enough points for this box size
            if n > N / 4 { continue }
            
            // Overlapping boxes for better stability
            let overlap = n / 2
            let step = max(1, n - overlap)
            var totalFluctuation: Double = 0
            var boxCount: Int = 0
            
            var start = 0
            while start + n <= N {
                let end = start + n
                let xBox = (0..<n).map { Double($0) }
                let yBox = Array(y[start..<end])
                
                let (slope, intercept) = linearRegression(x: xBox, y: yBox)
                
                var boxFluctuation: Double = 0
                for i in 0..<n {
                    let trendY = slope * Double(i) + intercept
                    let diff = yBox[i] - trendY
                    boxFluctuation += diff * diff
                }
                totalFluctuation += boxFluctuation / Double(n)
                boxCount += 1
                start += step
            }
            
            if boxCount > 0 {
                let Fn = sqrt(totalFluctuation / Double(boxCount))
                if Fn > 0 {
                    logN.append(log10(Double(n)))
                    logF.append(log10(Fn))
                }
            }
        }
        
        // We need at least 4 data points in the log-log plot to trust the alpha1 slope
        guard logN.count >= 4 else { return nil }
        
        let (alpha1, _) = linearRegression(x: logN, y: logF)
        
        // Physiological bounds check (Alpha 1 is typically between 0.3 and 1.7)
        if alpha1.isFinite && alpha1 > 0.2 && alpha1 < 1.8 {
            return alpha1
        }
        return nil
    }
    
    nonisolated private static func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double) {
        guard x.count == y.count && x.count > 1 else { return (0, 0) }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        
        let denominator = (n * sumX2 - sumX * sumX)
        guard abs(denominator) > 1e-10 else { return (0, 0) }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        return (slope, intercept)
    }
}
