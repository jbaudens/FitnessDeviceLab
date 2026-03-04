import Foundation

nonisolated public struct CalculatedMetrics {
    // Power
    public var power3s: Int?
    public var power10s: Int?
    public var power30s: Int?
    public var avgPower: Double?
    public var maxPower: Int?
    public var normalizedPower: Double?
    public var intensityFactor: Double?
    public var tss: Double?
    public var altitudeAdjustedPowerAcclimated: Int?
    public var altitudeAdjustedPowerNonAcclimated: Int?
    
    // Heart Rate
    public var avgHeartRate: Double?
    public var maxHeartRate: Int?
    
    // Cadence
    public var avgCadence: Double?
    public var maxCadence: Int?
    
    public init(power3s: Int? = nil, power10s: Int? = nil, power30s: Int? = nil, avgPower: Double? = nil, maxPower: Int? = nil, normalizedPower: Double? = nil, intensityFactor: Double? = nil, tss: Double? = nil, altitudeAdjustedPowerAcclimated: Int? = nil, altitudeAdjustedPowerNonAcclimated: Int? = nil, avgHeartRate: Double? = nil, maxHeartRate: Int? = nil, avgCadence: Double? = nil, maxCadence: Int? = nil) {
        self.power3s = power3s
        self.power10s = power10s
        self.power30s = power30s
        self.avgPower = avgPower
        self.maxPower = maxPower
        self.normalizedPower = normalizedPower
        self.intensityFactor = intensityFactor
        self.tss = tss
        self.altitudeAdjustedPowerAcclimated = altitudeAdjustedPowerAcclimated
        self.altitudeAdjustedPowerNonAcclimated = altitudeAdjustedPowerNonAcclimated
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.avgCadence = avgCadence
        self.maxCadence = maxCadence
    }
}

public struct DataFieldEngine {
    
    nonisolated public static func calculate(from trackpoints: [Trackpoint], userFTP: Double, currentAltitude: Double?) -> CalculatedMetrics {
        var metrics = CalculatedMetrics()
        
        let powerSamples = trackpoints.compactMap { $0.power }
        let hrSamples = trackpoints.compactMap { $0.hr }
        let cadenceSamples = trackpoints.compactMap { $0.cadence }
        
        // 1. Heart Rate Metrics
        if !hrSamples.isEmpty {
            metrics.avgHeartRate = Double(hrSamples.reduce(0, +)) / Double(hrSamples.count)
            metrics.maxHeartRate = hrSamples.max()
        }
        
        // 2. Cadence Metrics
        if !cadenceSamples.isEmpty {
            metrics.avgCadence = Double(cadenceSamples.reduce(0, +)) / Double(cadenceSamples.count)
            metrics.maxCadence = cadenceSamples.max()
        }
        
        // 3. Power Metrics
        if !powerSamples.isEmpty {
            metrics.avgPower = Double(powerSamples.reduce(0, +)) / Double(powerSamples.count)
            metrics.maxPower = powerSamples.max()
            
            // Rolling Averages
            metrics.power3s = rollingAverage(samples: powerSamples, window: 3)
            metrics.power10s = rollingAverage(samples: powerSamples, window: 10)
            metrics.power30s = rollingAverage(samples: powerSamples, window: 30)
            
            // NP®, IF®, TSS®
            var rolling30sHistory: [Double] = []
            for i in 0..<powerSamples.count {
                let start = max(0, i - 29)
                let window = powerSamples[start...i]
                let avg = Double(window.reduce(0, +)) / Double(window.count)
                rolling30sHistory.append(avg)
            }
            
            if !rolling30sHistory.isEmpty {
                let sum4 = rolling30sHistory.reduce(0) { $0 + pow($1, 4) }
                let avg4 = sum4 / Double(rolling30sHistory.count)
                let np = pow(avg4, 0.25)
                metrics.normalizedPower = np
                
                metrics.intensityFactor = np / userFTP
                let durationSeconds = Double(powerSamples.count)
                metrics.tss = (durationSeconds * np * (metrics.intensityFactor ?? 0)) / (userFTP * 3600.0) * 100.0
            }
            
            // Altitude adjustment for the latest sample
            if let p = powerSamples.last {
                let alt = currentAltitude ?? 0.0 // Default to sea level if GPS not available yet
                let h = max(0, alt / 1000.0) // Elevation in km
                let p_acc = max(0.5, 1.0 - 0.0112 * pow(h, 2) - 0.0190 * h)
                let p_non = max(0.5, 1.0 - 0.0125 * pow(h, 2) - 0.0260 * h)
                
                metrics.altitudeAdjustedPowerAcclimated = Int(round(Double(p) / p_acc))
                metrics.altitudeAdjustedPowerNonAcclimated = Int(round(Double(p) / p_non))
            }
        }
        
        return metrics
    }
    
    nonisolated private static func rollingAverage(samples: [Int], window: Int) -> Int? {
        guard !samples.isEmpty else { return nil }
        let count = min(samples.count, window)
        let slice = samples.suffix(count)
        return Int(round(Double(slice.reduce(0, +)) / Double(count)))
    }
}
