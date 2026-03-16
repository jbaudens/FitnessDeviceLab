import Foundation

public struct ComparisonPoint: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let elapsedSeconds: TimeInterval
    public let powerA: Int?
    public let powerB: Int?
    
    public var delta: Int? {
        guard let a = powerA, let b = powerB else { return nil }
        return a - b
    }
    
    public var percentDelta: Double? {
        guard let a = powerA, let b = powerB, b > 0 else { return nil }
        return (Double(a - b) / Double(b)) * 100.0
    }
}

public struct DetectedInterval: Identifiable {
    public let id = UUID()
    public let startSeconds: TimeInterval
    public let endSeconds: TimeInterval
    public let duration: TimeInterval
    public let avgPowerA: Double
    public let avgPowerB: Double
    
    public var delta: Double { avgPowerA - avgPowerB }
    public var percentDelta: Double { (delta / avgPowerB) * 100.0 }
    public var intensity: Int { Int(avgPowerB) }
}

public struct ComparisonSummary {
    public let avgPowerA: Double
    public let avgPowerB: Double
    public let maxPowerA: Int
    public let maxPowerB: Int
    public let avgDelta: Double
    public let maxDelta: Int
    public let totalPoints: Int
    public let divergencePoints: Int 
    public let detectedIntervals: [DetectedInterval]
    public let estimatedDrift: Double? 
}

public class PowerComparisonEngine {
    
    public static func alignAndCompare(pointsA: [Trackpoint], pointsB: [Trackpoint]) -> [ComparisonPoint] {
        guard let startA = pointsA.first?.time, let startB = pointsB.first?.time,
              let endA = pointsA.last?.time, let endB = pointsB.last?.time else {
            return []
        }
        
        let startTime = max(startA, startB)
        let endTime = min(endA, endB)
        
        var comparisonPoints: [ComparisonPoint] = []
        var currentTime = startTime
        while currentTime <= endTime {
            let pA = findClosestPower(at: currentTime, in: pointsA)
            let pB = findClosestPower(at: currentTime, in: pointsB)
            
            let elapsed = currentTime.timeIntervalSince(startTime)
            comparisonPoints.append(ComparisonPoint(timestamp: currentTime, elapsedSeconds: elapsed, powerA: pA, powerB: pB))
            currentTime = currentTime.addingTimeInterval(1.0)
        }
        
        return comparisonPoints
    }
    
    public static func summarize(points: [ComparisonPoint]) -> ComparisonSummary {
        let validPoints = points.filter { $0.powerA != nil && $0.powerB != nil }
        guard !validPoints.isEmpty else {
            return ComparisonSummary(
                avgPowerA: 0, avgPowerB: 0, maxPowerA: 0, maxPowerB: 0, 
                avgDelta: 0, maxDelta: 0, totalPoints: 0, divergencePoints: 0, 
                detectedIntervals: [], estimatedDrift: nil
            )
        }
        
        let avgA = validPoints.compactMap { Double($0.powerA!) }.reduce(0, +) / Double(validPoints.count)
        let avgB = validPoints.compactMap { Double($0.powerB!) }.reduce(0, +) / Double(validPoints.count)
        let maxA = validPoints.compactMap { $0.powerA! }.max() ?? 0
        let maxB = validPoints.compactMap { $0.powerB! }.max() ?? 0
        
        let deltas = validPoints.compactMap { Double(abs($0.delta!)) }
        let avgDelta = deltas.reduce(0, +) / Double(deltas.count)
        let maxDelta = validPoints.compactMap { abs($0.delta!) }.max() ?? 0
        
        let divergenceCount = validPoints.filter { abs($0.percentDelta ?? 0) > 5.0 }.count
        
        let intervals = detectIntervals(in: points)
        let drift = calculateDrift(intervals: intervals)
        
        return ComparisonSummary(
            avgPowerA: avgA,
            avgPowerB: avgB,
            maxPowerA: maxA,
            maxPowerB: maxB,
            avgDelta: avgDelta,
            maxDelta: maxDelta,
            totalPoints: validPoints.count,
            divergencePoints: divergenceCount,
            detectedIntervals: intervals,
            estimatedDrift: drift
        )
    }
    
    /// Detects sustained power intervals using a delta-based threshold (catching changes in intensity).
    public static func detectIntervals(in points: [ComparisonPoint]) -> [DetectedInterval] {
        let windowSize = 5
        let minDuration: TimeInterval = 15.0
        
        var intervals: [DetectedInterval] = []
        var currentStart: ComparisonPoint?
        var currentBasePower: Double?
        
        func finalizeInterval(end: ComparisonPoint) {
            guard let start = currentStart else { return }
            let duration = end.elapsedSeconds - start.elapsedSeconds
            if duration >= minDuration {
                let intervalPoints = points.filter { $0.elapsedSeconds >= start.elapsedSeconds && $0.elapsedSeconds <= end.elapsedSeconds }
                let avgA = intervalPoints.compactMap { Double($0.powerA ?? 0) }.reduce(0, +) / Double(intervalPoints.count)
                let avgB = intervalPoints.compactMap { Double($0.powerB ?? 0) }.reduce(0, +) / Double(intervalPoints.count)
                
                intervals.append(DetectedInterval(
                    startSeconds: start.elapsedSeconds,
                    endSeconds: end.elapsedSeconds,
                    duration: duration,
                    avgPowerA: avgA,
                    avgPowerB: avgB
                ))
            }
        }
        
        for i in 0..<(points.count - windowSize) {
            let slice = points[i..<i+windowSize]
            let avgPower = slice.compactMap { Double($0.powerB ?? 0) }.reduce(0, +) / Double(windowSize)
            
            if let base = currentBasePower {
                // If power changes by more than 15% or 30w, it's a new interval
                let powerDiff = abs(avgPower - base)
                let percentDiff = powerDiff / base
                
                if powerDiff > 30 || percentDiff > 0.15 {
                    // Finalize current and start new
                    finalizeInterval(end: points[i])
                    currentStart = points[i]
                    currentBasePower = avgPower
                }
            } else {
                // Initial start
                currentStart = points[i]
                currentBasePower = avgPower
            }
        }
        
        if let lastPoint = points.last {
            finalizeInterval(end: lastPoint)
        }
        
        return intervals
    }
    
    private static func calculateDrift(intervals: [DetectedInterval]) -> Double? {
        guard intervals.count >= 2 else { return nil }
        
        var results: [Double] = []
        for i in 0..<intervals.count {
            for j in (i+1)..<intervals.count {
                let pDiff = abs(intervals[i].avgPowerB - intervals[j].avgPowerB)
                // If intensities are within 10% or 15w, consider them "comparable" for drift
                let pBase = max(intervals[i].avgPowerB, 1.0)
                if pDiff < 15 || (pDiff / pBase) < 0.1 { 
                    let hourDiff = (intervals[j].startSeconds - intervals[i].startSeconds) / 3600.0
                    if hourDiff > 0.1 { 
                        let deltaChange = intervals[j].delta - intervals[i].delta
                        results.append(deltaChange / hourDiff)
                    }
                }
            }
        }
        
        return results.isEmpty ? nil : results.reduce(0, +) / Double(results.count)
    }
    
    private static func findClosestPower(at time: Date, in points: [Trackpoint]) -> Int? {
        let threshold: TimeInterval = 2.0
        let closest = points.first { abs($0.time.timeIntervalSince(time)) < 0.5 }
        if let p = closest?.power { return p }
        
        let lastKnown = points.last { $0.time <= time && time.timeIntervalSince($0.time) < threshold }
        return lastKnown?.power
    }
}
