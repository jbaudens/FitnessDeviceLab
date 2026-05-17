import Foundation

public actor ComputationActor {
    public init() {}
    
    public func calculateMetrics(
        trackpoints: [Trackpoint],
        relevantPoints: [Trackpoint],
        lapStartTime: Date?,
        metricsSettings: MetricsSettings
    ) -> (sessionComplex: AggregatedMetrics, lapComplex: AggregatedMetrics, hrv: HRVMetrics)? {
        
        if Task.isCancelled { return nil }
        let (sessionComplex, _) = DataFieldEngine.calculate(from: trackpoints, settings: metricsSettings, includeComplex: true)
        
        if Task.isCancelled { return nil }
        let lapComplex: AggregatedMetrics = {
            if let start = lapStartTime {
                let lapPoints = trackpoints.filter { $0.time >= start }
                let (m, _) = DataFieldEngine.calculate(from: lapPoints, settings: metricsSettings, includeComplex: true)
                return m
            }
            return AggregatedMetrics()
        }()
        
        if Task.isCancelled { return nil }
        let beats = relevantPoints.flatMap { pt in
            pt.rrIntervals.map { rr in Beat(time: pt.time, rr: rr) }
        }
        let newHRV = HRVEngine.calculateMetrics(beats: beats)
        
        if Task.isCancelled { return nil }
        return (sessionComplex, lapComplex, newHRV)
    }
}
