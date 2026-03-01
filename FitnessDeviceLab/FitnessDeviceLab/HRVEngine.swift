import Foundation
import Combine

public enum HRVMeasurementMode {
    case resting
    case biofeedback
    case exercise
}

public struct HRVConfig {
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

public class HRVEngine: ObservableObject {
    // Time Domain Metrics
    @Published public var avnn: Double?
    @Published public var sdnn: Double?
    @Published public var rmssd: Double?
    @Published public var pnn50: Double?
    
    // Non-linear Metrics
    @Published public var dfaAlpha1: Double?
    
    // Frequency Domain Metrics (Placeholders for now)
    @Published public var lf: Double?
    @Published public var hf: Double?
    @Published public var lf_hf_ratio: Double?
    
    private var rrBuffer: [Double] = []
    private var timestamps: [Date] = []
    public var config: HRVConfig
    
    public init(config: HRVConfig = .hrvLoggerExercise) {
        self.config = config
    }
    
    public func addRRIntervals(_ intervals: [Double], timestamp: Date = Date()) {
        let now = timestamp
        
        // Artifact removal
        for rr in intervals {
            // Guard against extreme values (under 30 BPM or over 200 BPM equivalent roughly)
            if rr < 0.3 || rr > 2.0 { continue }
            
            if let last = rrBuffer.last {
                let diff = abs(rr - last) / last
                if diff > config.artifactCorrectionThreshold {
                    // In a more advanced implementation, we would interpolate here.
                    continue 
                }
            }
            rrBuffer.append(rr)
            timestamps.append(now)
        }
        
        // Keep buffer to window size
        let windowCutoff = now.addingTimeInterval(-Double(config.windowSizeSeconds))
        
        while let firstTimestamp = timestamps.first, firstTimestamp < windowCutoff {
            timestamps.removeFirst()
            if !rrBuffer.isEmpty {
                rrBuffer.removeFirst()
            }
        }
        
        // Need a minimum amount of data to calculate meaningful stats
        // E.g. at least 60 intervals for exercise DFA, or more for 5-min resting
        let minIntervals = config.mode == .resting ? 150 : 60
        
        if rrBuffer.count >= minIntervals {
            calculateMetrics(rrIntervals: rrBuffer)
        }
    }
    
    private func calculateMetrics(rrIntervals: [Double]) {
        let N = rrIntervals.count
        guard N > 1 else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Time Domain
            let meanRR = rrIntervals.reduce(0, +) / Double(N)
            let variance = rrIntervals.map { pow($0 - meanRR, 2) }.reduce(0, +) / Double(N - 1)
            let sdnn = sqrt(variance)
            
            var diffSqSum: Double = 0
            var nn50Count: Int = 0
            
            for i in 1..<N {
                let diff = abs(rrIntervals[i] - rrIntervals[i-1])
                diffSqSum += (diff * diff)
                if diff > 0.05 { // 50 ms
                    nn50Count += 1
                }
            }
            
            let rmssd = sqrt(diffSqSum / Double(N - 1))
            let pnn50 = (Double(nn50Count) / Double(N - 1)) * 100.0
            
            // 2. DFA Alpha 1
            let dfa = self.calculateDFAAlpha1(rrIntervals: rrIntervals, meanRR: meanRR, N: N)
            
            // 3. Frequency Domain (Requires Lomb-Scargle or FFT + Interpolation)
            // Stubs for now. Real implementation requires accelerating framework.
            
            DispatchQueue.main.async {
                self.avnn = meanRR * 1000.0 // ms
                self.sdnn = sdnn * 1000.0 // ms
                self.rmssd = rmssd * 1000.0 // ms
                self.pnn50 = pnn50
                self.dfaAlpha1 = dfa
            }
        }
    }
    
    private func calculateDFAAlpha1(rrIntervals: [Double], meanRR: Double, N: Int) -> Double? {
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
                
                let (slope, intercept) = self.linearRegression(x: xBox, y: yBox)
                
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
        
        let (alpha1, _) = self.linearRegression(x: logN, y: logF)
        
        if alpha1.isFinite && alpha1 > 0.0 && alpha1 < 2.0 {
            return alpha1
        }
        return nil
    }
    
    private func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double) {
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
    
    public func reset() {
        rrBuffer.removeAll()
        timestamps.removeAll()
        avnn = nil
        sdnn = nil
        rmssd = nil
        pnn50 = nil
        dfaAlpha1 = nil
        lf = nil
        hf = nil
        lf_hf_ratio = nil
    }
}
