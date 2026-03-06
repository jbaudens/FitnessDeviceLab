import Foundation

public struct PowerMetrics {
    public var instantPower: Int?
    public var power3s: Int?
    public var power10s: Int?
    public var power30s: Int?
    public var avgPower: Double?
    public var maxPower: Int?
    public var normalizedPower: Double?
    public var intensityFactor: Double?
    public var tss: Double?
    public var wattsPerKg: Double?
    public var ftp: Double?
    
    public init() {}
}

nonisolated public struct CalculatedMetrics {
    // Three tracks of power analysis
    public var standard = PowerMetrics() // Raw data at current altitude
    public var seaLevel = PowerMetrics() // Normalized to 0m
    public var home = PowerMetrics()     // Normalized to user's ftpAltitude
    
    // Heart Rate
    public var avgHeartRate: Double?
    public var maxHeartRate: Int?
    
    // Cadence
    public var avgCadence: Double?
    public var maxCadence: Int?
    
    public init() {}
}

public struct DataFieldEngine {
    
    nonisolated private static func getAltitudeRatio(meters: Double) -> Double {
        let h = max(0, meters / 1000.0) // km
        // Using the "acclimated" curve as the base for normalization
        return max(0.5, 1.0 - 0.0112 * pow(h, 2) - 0.0190 * h)
    }
    
    nonisolated public static func calculate(from trackpoints: [Trackpoint], userFTP: Double, userWeight: Double, ftpAltitude: Double, currentAltitude: Double?) -> CalculatedMetrics {
        var metrics = CalculatedMetrics()
        
        let powerSamples = trackpoints.compactMap { $0.power }
        let hrSamples = trackpoints.compactMap { $0.hr }
        let cadenceSamples = trackpoints.compactMap { $0.cadence }
        
        // 0. FTP References
        let homeRatio = getAltitudeRatio(meters: ftpAltitude)
        let seaLevelFTP = userFTP / homeRatio
        
        metrics.home.ftp = userFTP
        metrics.seaLevel.ftp = seaLevelFTP
        
        let currentAlt = currentAltitude ?? 0.0
        let currentRatio = getAltitudeRatio(meters: currentAlt)
        metrics.standard.ftp = seaLevelFTP * currentRatio
        
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
            let lastPower = powerSamples.last ?? 0
            
            // Standard (Raw)
            metrics.standard.instantPower = lastPower
            metrics.standard.avgPower = Double(powerSamples.reduce(0, +)) / Double(powerSamples.count)
            metrics.standard.maxPower = powerSamples.max()
            metrics.standard.wattsPerKg = Double(lastPower) / userWeight
            
            // Sea Level (Normalized to 0m)
            let slPowers = trackpoints.compactMap { tp -> Double? in
                guard let p = tp.power else { return nil }
                let ratio = getAltitudeRatio(meters: tp.altitude ?? 0.0)
                return Double(p) / ratio
            }
            let lastSLPower = slPowers.last ?? 0.0
            metrics.seaLevel.instantPower = Int(round(lastSLPower))
            metrics.seaLevel.avgPower = slPowers.reduce(0, +) / Double(slPowers.count)
            metrics.seaLevel.maxPower = Int(round(slPowers.max() ?? 0))
            metrics.seaLevel.wattsPerKg = lastSLPower / userWeight
            
            // Home (Normalized to ftpAltitude)
            let homePowers = slPowers.map { $0 * homeRatio }
            let lastHomePower = lastSLPower * homeRatio
            metrics.home.instantPower = Int(round(lastHomePower))
            metrics.home.avgPower = homePowers.reduce(0, +) / Double(homePowers.count)
            metrics.home.maxPower = Int(round(homePowers.max() ?? 0))
            metrics.home.wattsPerKg = lastHomePower / userWeight
            
            // Rolling Averages
            metrics.standard.power3s = rollingAverage(samples: powerSamples, window: 3)
            metrics.standard.power10s = rollingAverage(samples: powerSamples, window: 10)
            metrics.standard.power30s = rollingAverage(samples: powerSamples, window: 30)
            
            metrics.seaLevel.power3s = rollingAverageDouble(samples: slPowers, window: 3)
            metrics.seaLevel.power10s = rollingAverageDouble(samples: slPowers, window: 10)
            metrics.seaLevel.power30s = rollingAverageDouble(samples: slPowers, window: 30)
            
            metrics.home.power3s = rollingAverageDouble(samples: homePowers, window: 3)
            metrics.home.power10s = rollingAverageDouble(samples: homePowers, window: 10)
            metrics.home.power30s = rollingAverageDouble(samples: homePowers, window: 30)
            
            // Calculate NP, IF, TSS for all tracks
            var std30s = [Double](), sl30s = [Double](), home30s = [Double]()
            
            for i in 0..<trackpoints.count {
                let start = max(0, i - 29)
                let window = trackpoints[start...i]
                
                // Standard
                let powers = window.compactMap { $0.power }
                if !powers.isEmpty {
                    let stdAvg = Double(powers.reduce(0, +)) / Double(powers.count)
                    std30s.append(stdAvg)
                }
                
                // Sea Level
                let slPowersInWindow = window.compactMap { tp -> Double? in
                    guard let p = tp.power else { return nil }
                    return Double(p) / getAltitudeRatio(meters: tp.altitude ?? 0.0)
                }
                if !slPowersInWindow.isEmpty {
                    let slAvg = slPowersInWindow.reduce(0, +) / Double(slPowersInWindow.count)
                    sl30s.append(slAvg)
                    home30s.append(slAvg * homeRatio)
                }
            }
            
            computeNPBasedMetrics(rolling30s: std30s, ftp: userFTP, metrics: &metrics.standard)
            computeNPBasedMetrics(rolling30s: sl30s, ftp: seaLevelFTP, metrics: &metrics.seaLevel)
            computeNPBasedMetrics(rolling30s: home30s, ftp: userFTP, metrics: &metrics.home)
        }
        
        return metrics
    }
    
    nonisolated private static func computeNPBasedMetrics(rolling30s: [Double], ftp: Double, metrics: inout PowerMetrics) {
        guard !rolling30s.isEmpty else { return }
        let sum4 = rolling30s.reduce(0) { $0 + pow($1, 4) }
        let np = pow(sum4 / Double(rolling30s.count), 0.25)
        metrics.normalizedPower = np
        metrics.intensityFactor = np / ftp
        let durationSeconds = Double(rolling30s.count)
        metrics.tss = (durationSeconds * np * (metrics.intensityFactor ?? 0)) / (ftp * 3600.0) * 100.0
    }
    
    nonisolated private static func rollingAverage(samples: [Int], window: Int) -> Int? {
        guard !samples.isEmpty else { return nil }
        let count = min(samples.count, window)
        let slice = samples.suffix(count)
        return Int(round(Double(slice.reduce(0, +)) / Double(count)))
    }
    
    nonisolated private static func rollingAverageDouble(samples: [Double], window: Int) -> Int? {
        guard !samples.isEmpty else { return nil }
        let count = min(samples.count, window)
        let slice = samples.suffix(count)
        return Int(round(slice.reduce(0, +) / Double(count)))
    }
}
