import Foundation
import Observation

// MARK: - Sub-Metric Structs

nonisolated public struct HeartRateMetrics {
    public var avg: Double?
    public var max: Int?
    public var min: Int?
    public init() {}
}

nonisolated public struct SpeedMetrics {
    public var avg: Double?
    public var max: Double?
    public var distance: Double? // m
    public init() {}
}

nonisolated public struct CadenceMetrics {
    public var avg: Double?
    public var max: Int?
    public var min: Int?
    public init() {}
}

nonisolated public struct PowerMetrics {
    public var avgPower: Double?
    public var maxPower: Int?
    public var minPower: Int?
    public var normalizedPower: Double?
    public var intensityFactor: Double?
    public var tss: Double?
    public var ftp: Double?
    public init() {}
}

nonisolated public struct LivePowerMetrics {
    public var instant: Int?
    public var power3s: Int?
    public var power10s: Int?
    public var power30s: Int?
    public var wattsPerKg: Double?
    public init() {}
}

nonisolated public struct LiveMetrics {
    public var standard = LivePowerMetrics()
    public var seaLevel = LivePowerMetrics()
    public var home = LivePowerMetrics()
    public init() {}
}

// MARK: - Main Metric Containers

nonisolated public struct AggregatedMetrics {
    public var hr = HeartRateMetrics()
    public var cadence = CadenceMetrics()
    public var speed = SpeedMetrics()
    public var standard = PowerMetrics()
    public var seaLevel = PowerMetrics()
    public var home = PowerMetrics()
    
    public init() {}
    
    /// Merges basic metrics (Avg/Max/Min) from another instance.
    public mutating func updateBasic(from other: AggregatedMetrics) {
        self.hr.avg = other.hr.avg
        self.hr.max = other.hr.max
        self.hr.min = other.hr.min
        
        self.cadence.avg = other.cadence.avg
        self.cadence.max = other.cadence.max
        self.cadence.min = other.cadence.min
        
        self.speed.avg = other.speed.avg
        self.speed.max = other.speed.max
        self.speed.distance = other.speed.distance
        
        self.standard.avgPower = other.standard.avgPower
        self.standard.maxPower = other.standard.maxPower
        self.standard.minPower = other.standard.minPower
        
        self.seaLevel.avgPower = other.seaLevel.avgPower
        self.seaLevel.maxPower = other.seaLevel.maxPower
        self.seaLevel.minPower = other.seaLevel.minPower
        
        self.home.avgPower = other.home.avgPower
        self.home.maxPower = other.home.maxPower
        self.home.minPower = other.home.minPower
    }
    
    /// Merges complex metrics (NP/TSS) from another instance.
    public mutating func updateComplex(from other: AggregatedMetrics) {
        self.standard.normalizedPower = other.standard.normalizedPower
        self.standard.intensityFactor = other.standard.intensityFactor
        self.standard.tss = other.standard.tss
        
        self.seaLevel.normalizedPower = other.seaLevel.normalizedPower
        self.seaLevel.intensityFactor = other.seaLevel.intensityFactor
        self.seaLevel.tss = other.seaLevel.tss
        
        self.home.normalizedPower = other.home.normalizedPower
        self.home.intensityFactor = other.home.intensityFactor
        self.home.tss = other.home.tss
    }
}

nonisolated public struct MetricsSettings: Sendable {
    public let userFTP: Double
    public let userWeight: Double
    public let ftpAltitude: Double
    
    public init(userFTP: Double, userWeight: Double, ftpAltitude: Double) {
        self.userFTP = userFTP
        self.userWeight = userWeight
        self.ftpAltitude = ftpAltitude
    }
}

// MARK: - Engine

@Observable
public class DataFieldEngine {
    // CATEGORY 1 & 2: Live "Now" State
    public var currentHR: Int?
    public var currentCadence: Int?
    public var currentSpeed: Double?
    public var powerBalance: Double?
    
    public var liveStandard = LivePowerMetrics()
    public var liveSeaLevel = LivePowerMetrics()
    public var liveHome = LivePowerMetrics()
    
    public var currentAltitude: Double?
    public var localFTP: Double?
    public var slFTP: Double?
    
    // CATEGORY 3: Aggregated Metrics
    public var hrvMetrics = HRVMetrics()
    public var calculatedMetrics = AggregatedMetrics()
    public var currentLapMetrics = AggregatedMetrics()
    public var lapStartTime: Date? = nil
    
    // Incremental Calculation State (Session)
    private var totalPowerSum: Double = 0
    private var powerPointCount: Int = 0
    private var totalHRSum: Double = 0
    private var hrPointCount: Int = 0
    private var totalCadenceSum: Double = 0
    private var cadencePointCount: Int = 0
    private var totalDistance: Double = 0
    private var lastPoint: Trackpoint?
    
    /// Fixed-size buffer for high-frequency rolling metrics (3s, 10s, 30s)
    private var powerBuffer: [Int] = []
    private let maxBufferSize = 30
    
    // Incremental Calculation State (Lap)
    private var lapPowerSum: Double = 0
    private var lapPowerCount: Int = 0
    private var lapHRSum: Double = 0
    private var lapHRCount: Int = 0
    private var lapCadenceSum: Double = 0
    private var lapCadenceCount: Int = 0
    private var lapDistance: Double = 0
    
    // State Tracking for throttling
    private var complexMetricsLastUpdate: Date = .distantPast
    private let complexMetricsThrottle: TimeInterval = 2.0
    
    private let settings: SettingsProvider
    private var calculationTask: Task<Void, Never>?
    
    public init(settings: SettingsProvider) {
        self.settings = settings
    }
    
    /// Main entry point called every second.
    public func updateMetrics(from trackpoints: [Trackpoint], latestPoint: Trackpoint?, lapStartTime: Date?) {
        // If we have a new point (recording or just live), process it incrementally
        if let point = latestPoint {
            processNewPoint(point, lapStartTime: lapStartTime)
        }
        
        // Complex metrics still need the full array but are throttled and backgrounded
        if Date().timeIntervalSince(complexMetricsLastUpdate) >= complexMetricsThrottle {
            complexMetricsLastUpdate = Date()
            launchComplexMetricsTask(trackpoints: trackpoints, lapStartTime: lapStartTime)
        }
    }
    
    private func processNewPoint(_ point: Trackpoint, lapStartTime: Date?) {
        // 1. Update Category 1 (Instant) & Altitude Ratios
        self.currentHR = point.hr
        self.currentCadence = point.cadence
        self.powerBalance = point.powerBalance
        self.currentAltitude = point.altitude
        
        let currentAlt = point.altitude ?? 0.0
        let homeRatio = Self.getAltitudeRatio(meters: settings.ftpAltitude)
        let currentRatio = Self.getAltitudeRatio(meters: currentAlt)
        
        self.slFTP = settings.userFTP / homeRatio
        self.localFTP = (self.slFTP ?? 0) * currentRatio
        
        let totalWeight = settings.userWeight + Constants.Physics.defaultBikeWeight
        let speed = PhysicsUtilities.estimateSpeed(power: Double(point.power ?? 0), totalWeight: totalWeight)
        self.currentSpeed = speed
        
        // Populate Live Power (Category 1)
        let instantPower = point.power ?? 0
        let slP = Double(instantPower) / currentRatio
        let homeP = slP * homeRatio
        
        self.liveStandard.instant = instantPower
        self.liveStandard.wattsPerKg = Double(instantPower) / settings.userWeight
        self.liveSeaLevel.instant = Int(round(slP))
        self.liveSeaLevel.wattsPerKg = slP / settings.userWeight
        self.liveHome.instant = Int(round(homeP))
        self.liveHome.wattsPerKg = homeP / settings.userWeight
        
        // Populate Rolling Averages (O(1) window lookup)
        if let p = point.power {
            powerBuffer.append(p)
            if powerBuffer.count > maxBufferSize {
                powerBuffer.removeFirst()
            }
            
            // Standard
            self.liveStandard.power3s = Self.getRollingAvg(powerBuffer, window: 3)
            self.liveStandard.power10s = Self.getRollingAvg(powerBuffer, window: 10)
            self.liveStandard.power30s = Self.getRollingAvg(powerBuffer, window: 30)
            
            // Sea Level
            self.liveSeaLevel.power3s = self.liveStandard.power3s.map { Int(round(Double($0) / currentRatio)) }
            self.liveSeaLevel.power10s = self.liveStandard.power10s.map { Int(round(Double($0) / currentRatio)) }
            self.liveSeaLevel.power30s = self.liveStandard.power30s.map { Int(round(Double($0) / currentRatio)) }
            
            // Home
            self.liveHome.power3s = self.liveSeaLevel.power3s.map { Int(round(Double($0) * homeRatio)) }
            self.liveHome.power10s = self.liveSeaLevel.power10s.map { Int(round(Double($0) * homeRatio)) }
            self.liveHome.power30s = self.liveSeaLevel.power30s.map { Int(round(Double($0) * homeRatio)) }
        }
        
        // 2. Incremental Aggregates (O(1))
        
        // Distance
        if let lp = lastPoint {
            let dt = point.time.timeIntervalSince(lp.time)
            if dt > 0 && dt < 10 {
                let dist = speed * dt
                totalDistance += dist
                if let lapStart = lapStartTime, point.time >= lapStart {
                    // Check if lap just started
                    if lp.time < lapStart {
                        lapDistance = dist // Reset for new lap
                    } else {
                        lapDistance += dist
                    }
                }
            }
        }
        lastPoint = point
        
        // Session Power
        if let p = point.power {
            totalPowerSum += Double(p)
            powerPointCount += 1
            calculatedMetrics.standard.maxPower = max(calculatedMetrics.standard.maxPower ?? 0, p)
            calculatedMetrics.standard.minPower = min(calculatedMetrics.standard.minPower ?? Int.max, p)
        }
        
        // Session HR
        if let hr = point.hr {
            totalHRSum += Double(hr)
            hrPointCount += 1
            calculatedMetrics.hr.max = max(calculatedMetrics.hr.max ?? 0, hr)
            calculatedMetrics.hr.min = min(calculatedMetrics.hr.min ?? Int.max, hr)
        }
        
        // Session Cadence
        if let cad = point.cadence {
            totalCadenceSum += Double(cad)
            cadencePointCount += 1
            calculatedMetrics.cadence.max = max(calculatedMetrics.cadence.max ?? 0, cad)
            calculatedMetrics.cadence.min = min(calculatedMetrics.cadence.min ?? Int.max, cad)
        }
        
        // Update Session Averages
        if powerPointCount > 0 {
            let avg = totalPowerSum / Double(powerPointCount)
            calculatedMetrics.standard.avgPower = avg
            calculatedMetrics.standard.ftp = localFTP
            calculatedMetrics.seaLevel.avgPower = avg / currentRatio
            calculatedMetrics.seaLevel.ftp = slFTP ?? settings.userFTP
            calculatedMetrics.home.avgPower = (calculatedMetrics.seaLevel.avgPower ?? 0) * homeRatio
            calculatedMetrics.home.ftp = settings.userFTP
        }
        
        if hrPointCount > 0 {
            calculatedMetrics.hr.avg = totalHRSum / Double(hrPointCount)
        }
        
        if cadencePointCount > 0 {
            calculatedMetrics.cadence.avg = totalCadenceSum / Double(cadencePointCount)
        }
        calculatedMetrics.speed.distance = totalDistance
        
        // 3. Lap Aggregates
        if let lapStart = lapStartTime {
            // Reset lap accumulators if this is the first point of a new lap
            if self.lapStartTime != lapStart {
                self.lapStartTime = lapStart
                lapPowerSum = 0; lapPowerCount = 0
                lapHRSum = 0; lapHRCount = 0
                lapCadenceSum = 0; lapCadenceCount = 0
                lapDistance = 0
                currentLapMetrics = AggregatedMetrics()
            }
            
            if point.time >= lapStart {
                if let p = point.power {
                    lapPowerSum += Double(p)
                    lapPowerCount += 1
                    currentLapMetrics.standard.maxPower = max(currentLapMetrics.standard.maxPower ?? 0, p)
                }
                if let hr = point.hr {
                    lapHRSum += Double(hr)
                    lapHRCount += 1
                    currentLapMetrics.hr.max = max(currentLapMetrics.hr.max ?? 0, hr)
                }
                if let cad = point.cadence {
                    lapCadenceSum += Double(cad)
                    lapCadenceCount += 1
                    currentLapMetrics.cadence.max = max(currentLapMetrics.cadence.max ?? 0, cad)
                }
                
                if lapPowerCount > 0 { currentLapMetrics.standard.avgPower = lapPowerSum / Double(lapPowerCount) }
                if lapHRCount > 0 { currentLapMetrics.hr.avg = lapHRSum / Double(lapHRCount) }
                if lapCadenceCount > 0 { currentLapMetrics.cadence.avg = lapCadenceSum / Double(lapCadenceCount) }
                currentLapMetrics.speed.distance = lapDistance
            }
        } else {
            self.lapStartTime = nil
            currentLapMetrics = AggregatedMetrics()
        }
    }
    
    private func launchComplexMetricsTask(trackpoints: [Trackpoint], lapStartTime: Date?) {
        calculationTask?.cancel()
        
        let metricsSettings = settings.metricsSettings
        // Provide enough history for time-based windowing (e.g., last 600 trackpoints for 10 min buffer)
        let relevantPoints = trackpoints.suffix(600)
        let beats = relevantPoints.flatMap { pt in
            pt.rrIntervals.map { rr in Beat(time: pt.time, rr: rr) }
        }
        
        calculationTask = Task.detached(priority: .userInitiated) {
            if Task.isCancelled { return }
            
            // Session Complex
            let (sessionComplex, _) = Self.calculate(from: trackpoints, settings: metricsSettings, includeComplex: true)
            
            // Lap Complex
            let lapComplex: AggregatedMetrics = {
                if let start = lapStartTime {
                    // Filter in background
                    let lapPoints = trackpoints.filter { $0.time >= start }
                    let (m, _) = Self.calculate(from: lapPoints, settings: metricsSettings, includeComplex: true)
                    return m
                }
                return AggregatedMetrics()
            }()
            
            // HRV
            let newHRV = HRVEngine.calculateMetrics(beats: beats)
            
            if Task.isCancelled { return }
            
            await MainActor.run {
                // Update Complex (NP/TSS)
                self.calculatedMetrics.updateComplex(from: sessionComplex)
                self.currentLapMetrics.updateComplex(from: lapComplex)
                self.hrvMetrics = newHRV
            }
        }
    }
    
    // MARK: - Core Calculation Logic
    
    nonisolated public static func calculate(from trackpoints: [Trackpoint], settings: MetricsSettings, includeComplex: Bool = true) -> (AggregatedMetrics, LiveMetrics) {
        guard !trackpoints.isEmpty else { return (AggregatedMetrics(), LiveMetrics()) }
        
        let userFTP = settings.userFTP
        let userWeight = settings.userWeight
        let ftpAltitude = settings.ftpAltitude
        let totalWeight = userWeight + Constants.Physics.defaultBikeWeight
        
        let powerSamples = trackpoints.compactMap { $0.power }
        let hrSamples = trackpoints.compactMap { $0.hr }
        let cadenceSamples = trackpoints.compactMap { $0.cadence }
        
        let homeRatio = getAltitudeRatio(meters: ftpAltitude)
        let currentAlt = trackpoints.last?.altitude ?? 0.0
        let currentRatio = getAltitudeRatio(meters: currentAlt)
        let slFTPValue = userFTP / homeRatio
        let localFTP = slFTPValue * currentRatio
        
        var m = AggregatedMetrics()
        var live = LiveMetrics()
        
        // 1. Distance Estimation (Fast)
        var totalDist: Double = 0
        for i in 1..<trackpoints.count {
            let speed = PhysicsUtilities.estimateSpeed(power: Double(trackpoints[i].power ?? 0), totalWeight: totalWeight)
            let dt = trackpoints[i].time.timeIntervalSince(trackpoints[i-1].time)
            if dt > 0 && dt < 10 {
                totalDist += speed * dt
            }
        }
        m.speed.distance = totalDist
        
        // 2. Power Aggregates
        if !powerSamples.isEmpty {
            let sum = powerSamples.reduce(0, +)
            let avg = Double(sum) / Double(powerSamples.count)
            m.standard.avgPower = avg
            m.standard.maxPower = powerSamples.max()
            m.standard.minPower = powerSamples.min()
            m.standard.ftp = localFTP
            
            m.seaLevel.avgPower = avg / currentRatio
            m.seaLevel.maxPower = m.standard.maxPower.map { Int(round(Double($0) / currentRatio)) }
            m.seaLevel.minPower = m.standard.minPower.map { Int(round(Double($0) / currentRatio)) }
            m.seaLevel.ftp = slFTPValue
            
            m.home.avgPower = m.seaLevel.avgPower.map { $0 * homeRatio }
            m.home.maxPower = m.seaLevel.maxPower.map { Int(round(Double($0) * homeRatio)) }
            m.home.minPower = m.seaLevel.minPower.map { Int(round(Double($0) * homeRatio)) }
            m.home.ftp = userFTP
            
            if includeComplex {
                // Populate Standard Rolling
                live.standard.power3s = getRollingAvg(powerSamples, window: 3)
                live.standard.power10s = getRollingAvg(powerSamples, window: 10)
                live.standard.power30s = getRollingAvg(powerSamples, window: 30)
                
                // Populate Sea Level Rolling (derived from standard using current ratio)
                live.seaLevel.power3s = live.standard.power3s.map { Int(round(Double($0) / currentRatio)) }
                live.seaLevel.power10s = live.standard.power10s.map { Int(round(Double($0) / currentRatio)) }
                live.seaLevel.power30s = live.standard.power30s.map { Int(round(Double($0) / currentRatio)) }
                
                // Populate Home Rolling (derived from sea level using home ratio)
                live.home.power3s = live.seaLevel.power3s.map { Int(round(Double($0) * homeRatio)) }
                live.home.power10s = live.seaLevel.power10s.map { Int(round(Double($0) * homeRatio)) }
                live.home.power30s = live.seaLevel.power30s.map { Int(round(Double($0) * homeRatio)) }
                
                if powerSamples.count >= 30 {
                    let duration = trackpoints.last!.time.timeIntervalSince(trackpoints.first!.time)
                    let stdNP = PowerMath.calculateNP(fromSamples: powerSamples.map { Double($0) })
                    m.standard.normalizedPower = stdNP
                    if let np = stdNP {
                        let ifVal = PowerMath.calculateIF(np: np, ftp: localFTP)
                        m.standard.intensityFactor = ifVal
                        m.standard.tss = PowerMath.calculateTSS(durationSeconds: duration, np: np, ifValue: ifVal, ftp: localFTP)
                    }
                    
                    let slNP = (stdNP ?? 0) / currentRatio
                    m.seaLevel.normalizedPower = slNP
                    if slNP > 0 {
                        let ifVal = PowerMath.calculateIF(np: slNP, ftp: slFTPValue)
                        m.seaLevel.intensityFactor = ifVal
                        m.seaLevel.tss = PowerMath.calculateTSS(durationSeconds: duration, np: slNP, ifValue: ifVal, ftp: slFTPValue)
                    }
                    
                    let homeNP = slNP * homeRatio
                    m.home.normalizedPower = homeNP
                    if homeNP > 0 {
                        let ifVal = PowerMath.calculateIF(np: homeNP, ftp: userFTP)
                        m.home.intensityFactor = ifVal
                        m.home.tss = PowerMath.calculateTSS(durationSeconds: duration, np: homeNP, ifValue: ifVal, ftp: userFTP)
                    }
                }
            }
        }
        
        // 3. HR Aggregates
        if !hrSamples.isEmpty {
            m.hr.avg = Double(hrSamples.reduce(0, +)) / Double(hrSamples.count)
            m.hr.max = hrSamples.max()
            m.hr.min = hrSamples.min()
        }
        
        // 4. Cadence Aggregates
        if !cadenceSamples.isEmpty {
            m.cadence.avg = Double(cadenceSamples.reduce(0, +)) / Double(cadenceSamples.count)
            m.cadence.max = cadenceSamples.max()
            m.cadence.min = cadenceSamples.min()
        }
        
        return (m, live)
    }
    
    // MARK: - Helpers
    
    public func reset() {
        calculatedMetrics = AggregatedMetrics()
        currentLapMetrics = AggregatedMetrics()
        currentHR = nil
        currentCadence = nil
        powerBalance = nil
        hrvMetrics = HRVMetrics()
        
        let homeRatio = Self.getAltitudeRatio(meters: settings.ftpAltitude)
        self.slFTP = settings.userFTP / homeRatio
        self.localFTP = settings.userFTP // Default to user FTP until altitude known
        self.currentAltitude = settings.altitudeOverride
        
        // Reset incremental session state
        totalPowerSum = 0; powerPointCount = 0
        totalHRSum = 0; hrPointCount = 0
        totalCadenceSum = 0; cadencePointCount = 0
        totalDistance = 0
        lastPoint = nil
        powerBuffer = []
        
        // Reset incremental lap state
        lapPowerSum = 0; lapPowerCount = 0
        lapHRSum = 0; lapHRCount = 0
        lapCadenceSum = 0; lapCadenceCount = 0
        lapDistance = 0
        lapStartTime = nil
    }
    
    nonisolated public static func getAltitudeRatio(meters: Double) -> Double {
        let h = max(0, meters / 1000.0)
        return max(0.5, 1.0 - 0.0112 * pow(h, 2) - 0.0190 * h)
    }
    
    nonisolated private static func getRollingAvg(_ samples: [Int], window: Int) -> Int? {
        let count = min(samples.count, window)
        let slice = samples.suffix(count)
        return Int(round(Double(slice.reduce(0, +)) / Double(count)))
    }
}
