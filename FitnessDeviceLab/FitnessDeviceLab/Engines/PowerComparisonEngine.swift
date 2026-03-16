import Foundation

public struct ComparisonPoint: Identifiable {
    public let id = UUID()
    public let timestamp: Date
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
    public let start: Date
    public let end: Date
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
    public let estimatedDrift: Double? // Watts per hour drift
}

public class PowerComparisonEngine {
    
    public static func alignAndCompare(pointsA: [Trackpoint], pointsB: [Trackpoint]) -> [ComparisonPoint] {
        // Find common time range
        guard let startA = pointsA.first?.time, let startB = pointsB.first?.time,
              let endA = pointsA.last?.time, let endB = pointsB.last?.time else {
            return []
        }
        
        let startTime = max(startA, startB)
        let endTime = min(endA, endB)
        
        var comparisonPoints: [ComparisonPoint] = []
        
        // We iterate every second from start to end
        var currentTime = startTime
        while currentTime <= endTime {
            let pA = findClosestPower(at: currentTime, in: pointsA)
            let pB = findClosestPower(at: currentTime, in: pointsB)
            
            comparisonPoints.append(ComparisonPoint(timestamp: currentTime, powerA: pA, powerB: pB))
            currentTime = currentTime.addingTimeInterval(1.0)
        }
        
        return comparisonPoints
    }
    
    public static func summarize(points: [ComparisonPoint]) -> ComparisonSummary {
        let validPoints = points.filter { $0.powerA != nil && $0.powerB != nil }
        guard !validPoints.isEmpty else {
            return ComparisonSummary(
                avgPowerA: 0, 
                avgPowerB: 0, 
                maxPowerA: 0, 
                maxPowerB: 0, 
                avgDelta: 0, 
                maxDelta: 0, 
                totalPoints: 0, 
                divergencePoints: 0, 
                detectedIntervals: [], 
                estimatedDrift: nil
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
    
    public static func detectIntervals(in points: [ComparisonPoint]) -> [DetectedInterval] {
        let windowSize = 5 
        let minDuration: TimeInterval = 15.0
        let powerThreshold = 100.0
        
        var intervals: [DetectedInterval] = []
        var currentStart: Date?
        
        func finalizeInterval(end: Date) {
            guard let start = currentStart else { return }
            let duration = end.timeIntervalSince(start)
            if duration >= minDuration {
                let intervalPoints = points.filter { $0.timestamp >= start && $0.timestamp <= end }
                let avgA = intervalPoints.compactMap { Double($0.powerA ?? 0) }.reduce(0, +) / Double(intervalPoints.count)
                let avgB = intervalPoints.compactMap { Double($0.powerB ?? 0) }.reduce(0, +) / Double(intervalPoints.count)
                
                intervals.append(DetectedInterval(start: start, end: end, duration: duration, avgPowerA: avgA, avgPowerB: avgB))
            }
        }
        
        for i in 0..<(points.count - windowSize) {
            let slice = points[i..<i+windowSize]
            let avgPower = slice.compactMap { Double($0.powerB ?? 0) }.reduce(0, +) / Double(windowSize)
            
            if avgPower > powerThreshold {
                if currentStart == nil {
                    currentStart = points[i].timestamp
                }
            } else {
                if let _ = currentStart {
                    finalizeInterval(end: points[i].timestamp)
                    currentStart = nil
                }
            }
        }
        
        // Finalize if still in an interval at the end of the data
        if let start = currentStart, let lastTimestamp = points.last?.timestamp {
            finalizeInterval(end: lastTimestamp)
        }
        
        return intervals
    }
    
    private static func calculateDrift(intervals: [DetectedInterval]) -> Double? {
        guard intervals.count >= 2 else { return nil }
        
        var results: [Double] = []
        for i in 0..<intervals.count {
            for j in (i+1)..<intervals.count {
                let pDiff = abs(intervals[i].avgPowerB - intervals[j].avgPowerB)
                if pDiff < 20 { // Same intensity
                    let hourDiff = intervals[j].start.timeIntervalSince(intervals[i].start) / 3600.0
                    if hourDiff > 0.2 { // At least 12 mins apart
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
