import Foundation
import Combine

public struct DFAConfig {
    public var windowSizeSeconds: Int
    public var stepSizeSeconds: Int
    public var artifactCorrectionThreshold: Double // E.g. 0.20 (20%)
    
    public static let hrvLoggerGoldStandard = DFAConfig(
        windowSizeSeconds: 120, // 2 minutes
        stepSizeSeconds: 5,
        artifactCorrectionThreshold: 0.20
    )
}

public class DFAAlpha1Calculator: ObservableObject {
    @Published public var currentAlpha1: Double?
    
    private var rrBuffer: [Double] = []
    private var timestamps: [Date] = []
    private var config: DFAConfig
    
    public init(config: DFAConfig = .hrvLoggerGoldStandard) {
        self.config = config
    }
    
    public func addRRIntervals(_ intervals: [Double]) {
        let now = Date()
        
        // Artifact removal (simple thresholding based on previous interval)
        for rr in intervals {
            // Guard against extreme values to prevent calculation errors
            if rr < 0.3 || rr > 2.0 {
                continue // Ignore biologically unlikely RR intervals (over 200BPM or under 30BPM)
            }
            
            if let last = rrBuffer.last {
                let diff = abs(rr - last) / last
                if diff > config.artifactCorrectionThreshold {
                    continue 
                }
            }
            rrBuffer.append(rr)
            timestamps.append(now)
        }
        
        // Keep buffer to a reasonable size based on time window
        let windowCutoff = now.addingTimeInterval(-Double(config.windowSizeSeconds))
        
        while let firstTimestamp = timestamps.first, firstTimestamp < windowCutoff {
            timestamps.removeFirst()
            if !rrBuffer.isEmpty {
                rrBuffer.removeFirst()
            }
        }
        
        // Trigger calculation if we have enough data (at least 60 valid intervals)
        if rrBuffer.count >= 60 {
            // In a production app you'd throttle this to run once every `config.stepSizeSeconds`.
            // For this live demo, running it on an async queue every few beats is fine.
            calculateDFA(rrIntervals: rrBuffer)
        } else {
            DispatchQueue.main.async {
                self.currentAlpha1 = nil
            }
        }
    }
    
    private func calculateDFA(rrIntervals: [Double]) {
        let N = rrIntervals.count
        guard N >= 60 else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Mean and integration
            let meanRR = rrIntervals.reduce(0, +) / Double(N)
            var y = [Double]()
            y.reserveCapacity(N)
            var sum: Double = 0
            for rr in rrIntervals {
                sum += (rr - meanRR)
                y.append(sum)
            }
            
            // 2. Box sizes for Alpha 1 (short-term correlations)
            // Typically alpha 1 is calculated for box sizes between 4 and 16 beats.
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
            
            guard logN.count > 1 else { return }
            
            // 3. Final regression for alpha 1 (slope of log(F) vs log(n))
            let (alpha1, _) = self.linearRegression(x: logN, y: logF)
            
            // Validate output
            if alpha1.isFinite && alpha1 > 0.0 && alpha1 < 2.0 {
                DispatchQueue.main.async {
                    self.currentAlpha1 = alpha1
                }
            }
        }
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
        currentAlpha1 = nil
    }
}
