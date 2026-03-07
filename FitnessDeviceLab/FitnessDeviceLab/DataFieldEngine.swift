import Foundation
import Combine

nonisolated public struct HeartRateMetrics {
    public var avg: Double?
    public var max: Int?
    public var min: Int?
    public init() {}
}

nonisolated public struct CadenceMetrics {
    public var avg: Double?
    public var max: Int?
    public var min: Int?
    public init() {}
}

nonisolated public struct PowerMetrics {
    public var instantPower: Int?
    public var power3s: Int?
    public var power10s: Int?
    public var power30s: Int?
    public var avgPower: Double?
    public var maxPower: Int?
    public var minPower: Int?
    public var normalizedPower: Double?
    public var intensityFactor: Double?
    public var tss: Double?
    public var wattsPerKg: Double?
    public var ftp: Double?
    
    public init() {}
}

nonisolated public struct CalculatedMetrics {
    public var hr = HeartRateMetrics()
    public var cadence = CadenceMetrics()
    public var standard = PowerMetrics()
    public var seaLevel = PowerMetrics()
    public var home = PowerMetrics()
    
    public init() {}
}

public class DataFieldEngine: ObservableObject {
    @Published public var currentHR: Int?
    @Published public var currentCadence: Int?
    @Published public var powerBalance: Double?
    
    @Published public var currentAltitude: Double?
    @Published public var localFTP: Double?
    @Published public var slFTP: Double?
    
    @Published public var hrvMetrics = HRVMetrics()
    @Published public var calculatedMetrics = CalculatedMetrics()
    
    private var cancellables = Set<AnyCancellable>()
    public let recorder: SessionRecorder
    
    init(recorder: SessionRecorder) {
        self.recorder = recorder
        
        recorder.$trackpoints
            .receive(on: RunLoop.main)
            .sink { [weak self] trackpoints in
                self?.update(from: trackpoints)
            }
            .store(in: &cancellables)
            
        SettingsManager.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.recalculate()
                }
            }
            .store(in: &cancellables)
    }
    
    public func recalculate() {
        update(from: recorder.trackpoints)
    }
    
    private func update(from trackpoints: [Trackpoint]) {
        let m = Self.calculate(from: trackpoints)
        
        if let latest = trackpoints.last {
            self.currentHR = latest.hr
            self.currentCadence = latest.cadence
            self.powerBalance = latest.powerBalance
            self.currentAltitude = latest.altitude
        }
        
        let settings = SettingsManager.shared
        let homeRatio = Self.getAltitudeRatio(meters: settings.ftpAltitude)
        self.slFTP = settings.userFTP / homeRatio
        let currentRatio = Self.getAltitudeRatio(meters: currentAltitude ?? 0.0)
        self.localFTP = (self.slFTP ?? 0) * currentRatio

        let rrHistory = Array(trackpoints.flatMap { $0.rrIntervals }.suffix(600))
        Task.detached(priority: .userInitiated) {
            let newHRV = HRVEngine.calculateMetrics(rawRRIntervals: rrHistory)
            await MainActor.run {
                self.hrvMetrics = newHRV
            }
        }
        
        self.calculatedMetrics = m
    }
    
    public static func calculate(from trackpoints: [Trackpoint]) -> CalculatedMetrics {
        guard !trackpoints.isEmpty else { return CalculatedMetrics() }
        
        let settings = SettingsManager.shared
        let userFTP = settings.userFTP
        let userWeight = settings.userWeight
        let ftpAltitude = settings.ftpAltitude
        
        let powerSamples = trackpoints.compactMap { $0.power }
        let hrSamples = trackpoints.compactMap { $0.hr }
        let cadenceSamples = trackpoints.compactMap { $0.cadence }
        
        let homeRatio = getAltitudeRatio(meters: ftpAltitude)
        let slFTPValue = userFTP / homeRatio
        let currentAlt = trackpoints.last?.altitude ?? 0.0
        let currentRatio = getAltitudeRatio(meters: currentAlt)
        let localFTP = slFTPValue * currentRatio
        
        var m = CalculatedMetrics()
        
        if !powerSamples.isEmpty {
            let lastPower = Double(trackpoints.last?.power ?? 0)
            let lastSL = lastPower / currentRatio
            let lastHome = lastSL * homeRatio
            
            m.standard.instantPower = Int(round(lastPower))
            m.standard.avgPower = Double(powerSamples.reduce(0, +)) / Double(powerSamples.count)
            m.standard.maxPower = powerSamples.max()
            m.standard.minPower = powerSamples.min()
            m.standard.wattsPerKg = lastPower / userWeight
            m.standard.power3s = getRollingAvg(powerSamples, window: 3)
            m.standard.power10s = getRollingAvg(powerSamples, window: 10)
            m.standard.power30s = getRollingAvg(powerSamples, window: 30)
            m.standard.ftp = localFTP
            
            let slPowers = trackpoints.compactMap { tp -> Double? in
                guard let p = tp.power else { return nil }
                return Double(p) / getAltitudeRatio(meters: tp.altitude ?? 0.0)
            }
            m.seaLevel.instantPower = Int(round(lastSL))
            m.seaLevel.avgPower = slPowers.reduce(0, +) / Double(slPowers.count)
            m.seaLevel.maxPower = Int(round(slPowers.max() ?? 0))
            m.seaLevel.minPower = Int(round(slPowers.min() ?? 0))
            m.seaLevel.wattsPerKg = lastSL / userWeight
            m.seaLevel.power3s = getRollingAvgDouble(slPowers, window: 3)
            m.seaLevel.power10s = getRollingAvgDouble(slPowers, window: 10)
            m.seaLevel.power30s = getRollingAvgDouble(slPowers, window: 30)
            m.seaLevel.ftp = slFTPValue
            
            m.home.instantPower = Int(round(lastHome))
            m.home.avgPower = (m.seaLevel.avgPower ?? 0) * homeRatio
            m.home.maxPower = Int(round(Double(m.seaLevel.maxPower ?? 0) * homeRatio))
            m.home.minPower = Int(round(Double(m.seaLevel.minPower ?? 0) * homeRatio))
            m.home.wattsPerKg = lastHome / userWeight
            m.home.power3s = m.seaLevel.power3s.map { Int(round(Double($0) * homeRatio)) }
            m.home.power10s = m.seaLevel.power10s.map { Int(round(Double($0) * homeRatio)) }
            m.home.power30s = m.seaLevel.power30s.map { Int(round(Double($0) * homeRatio)) }
            m.home.ftp = userFTP
            
            if powerSamples.count >= 30 {
                calculateNPMetrics(trackpoints: trackpoints, homeRatio: homeRatio, userFTP: userFTP, slFTP: slFTPValue, metrics: &m)
            }
        }
        
        if !hrSamples.isEmpty {
            m.hr.avg = Double(hrSamples.reduce(0, +)) / Double(hrSamples.count)
            m.hr.max = hrSamples.max()
            m.hr.min = hrSamples.min()
        }
        
        if !cadenceSamples.isEmpty {
            m.cadence.avg = Double(cadenceSamples.reduce(0, +)) / Double(cadenceSamples.count)
            m.cadence.max = cadenceSamples.max()
            m.cadence.min = cadenceSamples.min()
        }
        
        return m
    }
    
    private static func calculateNPMetrics(trackpoints: [Trackpoint], homeRatio: Double, userFTP: Double, slFTP: Double, metrics: inout CalculatedMetrics) {
        var std30s = [Double](), sl30s = [Double](), home30s = [Double]()
        
        for i in 0..<trackpoints.count {
            let start = max(0, i - 29)
            let window = trackpoints[start...i]
            let powers = window.compactMap { $0.power }
            if powers.isEmpty { continue }
            
            let stdAvg = Double(powers.reduce(0, +)) / Double(powers.count)
            std30s.append(stdAvg)
            
            let slPowersInWindow = window.compactMap { tp -> Double? in
                guard let p = tp.power else { return nil }
                return Double(p) / getAltitudeRatio(meters: tp.altitude ?? 0.0)
            }
            let slAvg = slPowersInWindow.reduce(0, +) / Double(slPowersInWindow.count)
            sl30s.append(slAvg)
            home30s.append(slAvg * homeRatio)
        }
        
        metrics.standard.normalizedPower = calculateNPFromRolling(std30s)
        metrics.standard.intensityFactor = (metrics.standard.normalizedPower ?? 0) / userFTP
        metrics.standard.tss = (Double(std30s.count) * (metrics.standard.normalizedPower ?? 0) * (metrics.standard.intensityFactor ?? 0)) / (userFTP * 36.0)
        
        metrics.seaLevel.normalizedPower = calculateNPFromRolling(sl30s)
        metrics.seaLevel.intensityFactor = (metrics.seaLevel.normalizedPower ?? 0) / slFTP
        metrics.seaLevel.tss = (Double(sl30s.count) * (metrics.seaLevel.normalizedPower ?? 0) * (metrics.seaLevel.intensityFactor ?? 0)) / (slFTP * 36.0)
        
        metrics.home.normalizedPower = calculateNPFromRolling(home30s)
        metrics.home.intensityFactor = (metrics.home.normalizedPower ?? 0) / userFTP
        metrics.home.tss = (Double(home30s.count) * (metrics.home.normalizedPower ?? 0) * (metrics.home.intensityFactor ?? 0)) / (userFTP * 36.0)
    }
    
    private func reset() {
        calculatedMetrics = CalculatedMetrics()
        currentHR = nil
        currentCadence = nil
        powerBalance = nil
        hrvMetrics = HRVMetrics()
        localFTP = nil
        slFTP = nil
        currentAltitude = nil
    }
    
    nonisolated public static func getAltitudeRatio(meters: Double) -> Double {
        let h = max(0, meters / 1000.0)
        return max(0.5, 1.0 - 0.0112 * pow(h, 2) - 0.0190 * h)
    }
    
    private static func getRollingAvg(_ samples: [Int], window: Int) -> Int? {
        let count = min(samples.count, window)
        let slice = samples.suffix(count)
        return Int(round(Double(slice.reduce(0, +)) / Double(count)))
    }
    
    private static func getRollingAvgDouble(_ samples: [Double], window: Int) -> Int? {
        let count = min(samples.count, window)
        let slice = samples.suffix(count)
        return Int(round(slice.reduce(0, +) / Double(count)))
    }
    
    private static func calculateNPFromRolling(_ rolling: [Double]) -> Double {
        guard !rolling.isEmpty else { return 0 }
        let sum4 = rolling.reduce(0.0) { $0 + pow($1, 4) }
        return pow(sum4 / Double(rolling.count), 0.25)
    }
}
