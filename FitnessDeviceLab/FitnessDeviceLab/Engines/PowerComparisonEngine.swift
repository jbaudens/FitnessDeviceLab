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

public struct ComparisonSummary {
    public let avgPowerA: Double
    public let avgPowerB: Double
    public let maxPowerA: Int
    public let maxPowerB: Int
    public let avgDelta: Double
    public let maxDelta: Int
    public let totalPoints: Int
    public let divergencePoints: Int // Points where delta > 5%
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
            return ComparisonSummary(avgPowerA: 0, avgPowerB: 0, maxPowerA: 0, maxPowerB: 0, avgDelta: 0, maxDelta: 0, totalPoints: 0, divergencePoints: 0)
        }
        
        let avgA = validPoints.compactMap { Double($0.powerA!) }.reduce(0, +) / Double(validPoints.count)
        let avgB = validPoints.compactMap { Double($0.powerB!) }.reduce(0, +) / Double(validPoints.count)
        let maxA = validPoints.compactMap { $0.powerA! }.max() ?? 0
        let maxB = validPoints.compactMap { $0.powerB! }.max() ?? 0
        
        let deltas = validPoints.compactMap { Double(abs($0.delta!)) }
        let avgDelta = deltas.reduce(0, +) / Double(deltas.count)
        let maxDelta = validPoints.compactMap { abs($0.delta!) }.max() ?? 0
        
        let divergenceCount = validPoints.filter { abs($0.percentDelta ?? 0) > 5.0 }.count
        
        return ComparisonSummary(
            avgPowerA: avgA,
            avgPowerB: avgB,
            maxPowerA: maxA,
            maxPowerB: maxB,
            avgDelta: avgDelta,
            maxDelta: maxDelta,
            totalPoints: validPoints.count,
            divergencePoints: divergenceCount
        )
    }
    
    private static func findClosestPower(at time: Date, in points: [Trackpoint]) -> Int? {
        // Simple strategy: find exact second or last known within 2 seconds
        // In a more advanced version, we would interpolate
        let threshold: TimeInterval = 2.0
        let closest = points.first { abs($0.time.timeIntervalSince(time)) < 0.5 }
        if let p = closest?.power { return p }
        
        // Fallback to last known if within threshold
        let lastKnown = points.last { $0.time <= time && time.timeIntervalSince($0.time) < threshold }
        return lastKnown?.power
    }
}
