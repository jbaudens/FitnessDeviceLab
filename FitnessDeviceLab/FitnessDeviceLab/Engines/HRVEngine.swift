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
        windowSizeSeconds: 120,
        stepSizeSeconds: 5,
        artifactCorrectionThreshold: 0.20,
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

public struct HRVEngine {
    
    nonisolated public static func calculateMetrics(rawRRIntervals: [Double], config: HRVConfig = .hrvLoggerExercise) -> HRVMetrics {
        // 1. Time-based windowing
        // We expect rawRRIntervals to potentially be longer than the window.
        // We sum from the end until we reach windowSizeSeconds.
        var windowedRR: [Double] = []
        var totalTime: Double = 0
        for rr in rawRRIntervals.reversed() {
            totalTime += rr
            windowedRR.insert(rr, at: 0)
            if totalTime >= Double(config.windowSizeSeconds) { break }
        }
        
        // 2. Artifact removal & filtering on the windowed data
        var filteredRR: [Double] = []
        for rr in windowedRR {
            if rr < 0.3 || rr > 2.0 { continue }
            if let last = filteredRR.last {
                let diff = abs(rr - last) / last
                if diff > config.artifactCorrectionThreshold { continue }
            }
            filteredRR.append(rr)
        }
        
        let N = filteredRR.count
        // For DFA a1 we need a decent number of points even in exercise
        let minIntervals = config.mode == .resting ? 150 : 50
        guard N >= minIntervals else { return HRVMetrics() }
        
        // 1. Time Domain
        let meanRR = filteredRR.reduce(0, +) / Double(N)
        let variance = filteredRR.map { pow($0 - meanRR, 2) }.reduce(0, +) / Double(N - 1)
        let sdnn = sqrt(variance)
        
        var diffSqSum: Double = 0
        var nn50Count: Int = 0
        
        for i in 1..<N {
            let diff = abs(filteredRR[i] - filteredRR[i-1])
            diffSqSum += (diff * diff)
            if diff > 0.05 { // 50 ms
                nn50Count += 1
            }
        }
        
        let rmssd = sqrt(diffSqSum / Double(N - 1))
        let pnn50 = (Double(nn50Count) / Double(N - 1)) * 100.0
        
        // 2. DFA Alpha 1
        let dfa = calculateDFAAlpha1(rrIntervals: filteredRR, meanRR: meanRR, N: N)
        
        return HRVMetrics(
            avnn: meanRR * 1000.0,
            sdnn: sdnn * 1000.0,
            rmssd: rmssd * 1000.0,
            pnn50: pnn50,
            dfaAlpha1: dfa
        )
    }
    
    nonisolated private static func calculateDFAAlpha1(rrIntervals: [Double], meanRR: Double, N: Int) -> Double? {
        var y = [Double]()
        y.reserveCapacity(N)
        var sum: Double = 0
        for rr in rrIntervals {
            sum += (rr - meanRR)
            y.append(sum)
        }
        
        let boxSizes = [4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16]
        var logN = [Double]()
        var logF = [Double]()
        
        for n in boxSizes {
            if n > N / 2 { continue }
            
            let numBoxes = N / n
            var totalFluctuation: Double = 0
            
            for box in 0..<numBoxes {
                let start = box * n
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
                totalFluctuation += boxFluctuation
            }
            
            let Fn = sqrt(totalFluctuation / Double(numBoxes * n))
            if Fn > 0 {
                logN.append(log10(Double(n)))
                logF.append(log10(Fn))
            }
        }
        
        guard logN.count > 1 else { return nil }
        
        let (alpha1, _) = linearRegression(x: logN, y: logF)
        
        if alpha1.isFinite && alpha1 > 0.0 && alpha1 < 2.0 {
            return alpha1
        }
        return nil
    }
    
    nonisolated private static func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double) {
        guard x.count == y.count && x.count > 1 else { return (0, 0) }
        
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let n = Double(x.count)
        
        let denominator = (n * sumX2 - sumX * sumX)
        guard denominator != 0 else { return (0, 0) }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        return (slope, intercept)
    }
}
