import Foundation
import Combine

public class DataFieldEngine: ObservableObject {
    // Power
    @Published public var power3s: Int?
    @Published public var power10s: Int?
    @Published public var power30s: Int?
    @Published public var avgPower: Double?
    @Published public var maxPower: Int?
    @Published public var normalizedPower: Double?
    @Published public var intensityFactor: Double?
    @Published public var tss: Double?
    @Published public var altitudeAdjustedPowerAcclimated: Int?
    @Published public var altitudeAdjustedPowerNonAcclimated: Int?
    
    // Heart Rate
    @Published public var avgHeartRate: Double?
    @Published public var maxHeartRate: Int?
    
    // Cadence
    @Published public var avgCadence: Double?
    @Published public var maxCadence: Int?
    
    // HRV
    @Published public var avnn: Double?
    @Published public var sdnn: Double?
    @Published public var rmssd: Double?
    @Published public var pnn50: Double?
    @Published public var dfaAlpha1: Double?
    
    private var hrvEngine = HRVEngine()
    private var cancellables = Set<AnyCancellable>()
    
    // Time Series History for Charts (last 2 minutes)
    @Published public var hrHistory: [TimeSeriesDataPoint] = []
    @Published public var powerHistory: [TimeSeriesDataPoint] = []
    @Published public var balanceHistory: [TimeSeriesDataPoint] = []
    
    private var powerSamples: [Int] = []
    private var rolling30sPower: [Double] = []
    private var hrSamples: [Int] = []
    private var cadenceSamples: [Int] = []
    
    private var timerCancellable: AnyCancellable?
    
    public var userFTP: Double = 250.0 // Default FTP
    
    public init() {
        hrvEngine.$dfaAlpha1
            .receive(on: RunLoop.main)
            .sink { [weak self] val in self?.dfaAlpha1 = val }
            .store(in: &cancellables)
            
        hrvEngine.$avnn
            .receive(on: RunLoop.main)
            .sink { [weak self] val in self?.avnn = val }
            .store(in: &cancellables)
            
        hrvEngine.$sdnn
            .receive(on: RunLoop.main)
            .sink { [weak self] val in self?.sdnn = val }
            .store(in: &cancellables)
            
        hrvEngine.$rmssd
            .receive(on: RunLoop.main)
            .sink { [weak self] val in self?.rmssd = val }
            .store(in: &cancellables)
            
        hrvEngine.$pnn50
            .receive(on: RunLoop.main)
            .sink { [weak self] val in self?.pnn50 = val }
            .store(in: &cancellables)
    }
    
    public func start(getPower: @escaping () -> Int?, getHR: @escaping () -> Int?, getCadence: @escaping () -> Int?, getBalance: @escaping () -> Double?, getAltitude: @escaping () -> Double?) {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick(power: getPower(), hr: getHR(), cadence: getCadence(), balance: getBalance(), altitude: getAltitude())
            }
    }
    
    public func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func appendHistory<T>(_ value: T, to array: inout [TimeSeriesDataPoint], convert: (T) -> Double) {
        array.append(TimeSeriesDataPoint(value: convert(value)))
        if array.count > 120 { // Keep last ~2 mins at 1Hz
            array.removeFirst(array.count - 120)
        }
    }
    
    private func tick(power: Int?, hr: Int?, cadence: Int?, balance: Double?, altitude: Double?) {
        if let p = power {
            appendHistory(p, to: &powerHistory) { Double($0) }
            powerSamples.append(p)
            maxPower = max(maxPower ?? 0, p)
            avgPower = Double(powerSamples.reduce(0, +)) / Double(powerSamples.count)
            
            // Short rolling averages
            if powerSamples.count >= 3 {
                let last3 = powerSamples.suffix(3)
                power3s = Int(round(Double(last3.reduce(0, +)) / 3.0))
            } else {
                power3s = p
            }
            
            if powerSamples.count >= 10 {
                let last10 = powerSamples.suffix(10)
                power10s = Int(round(Double(last10.reduce(0, +)) / 10.0))
            } else {
                power10s = power3s
            }
            
            if powerSamples.count >= 30 {
                let last30 = powerSamples.suffix(30)
                let avg30 = Double(last30.reduce(0, +)) / 30.0
                power30s = Int(round(avg30))
                rolling30sPower.append(avg30)
                
                let sum4 = rolling30sPower.reduce(0) { $0 + pow($1, 4) }
                let avg4 = sum4 / Double(rolling30sPower.count)
                let np = pow(avg4, 0.25)
                normalizedPower = np
                
                // IF & TSS
                intensityFactor = np / userFTP
                let durationSeconds = Double(powerSamples.count)
                tss = (durationSeconds * np * (intensityFactor ?? 0)) / (userFTP * 3600.0) * 100.0
            } else {
                power30s = power10s
            }
            
            // Altitude adjustments
            if let alt = altitude {
                let h = max(0, alt / 1000.0) // Elevation in km
                let p_acc = max(0.5, 1.0 - 0.0112 * pow(h, 2) - 0.0190 * h)
                let p_non = max(0.5, 1.0 - 0.0125 * pow(h, 2) - 0.0260 * h)
                
                altitudeAdjustedPowerAcclimated = Int(round(Double(p) / p_acc))
                altitudeAdjustedPowerNonAcclimated = Int(round(Double(p) / p_non))
            }
        }
        
        if let h = hr {
            appendHistory(h, to: &hrHistory) { Double($0) }
            hrSamples.append(h)
            maxHeartRate = max(maxHeartRate ?? 0, h)
            avgHeartRate = Double(hrSamples.reduce(0, +)) / Double(hrSamples.count)
        }
        
        if let c = cadence {
            cadenceSamples.append(c)
            maxCadence = max(maxCadence ?? 0, c)
            avgCadence = Double(cadenceSamples.reduce(0, +)) / Double(cadenceSamples.count)
        }
        
        if let b = balance {
            appendHistory(b, to: &balanceHistory) { $0 }
        }
    }
    
    public func addRRIntervals(_ intervals: [Double]) {
        hrvEngine.addRRIntervals(intervals)
    }
    
    public func reset() {
        power3s = nil
        power10s = nil
        power30s = nil
        avgPower = nil
        maxPower = nil
        normalizedPower = nil
        intensityFactor = nil
        tss = nil
        altitudeAdjustedPowerAcclimated = nil
        altitudeAdjustedPowerNonAcclimated = nil
        avgHeartRate = nil
        maxHeartRate = nil
        avgCadence = nil
        maxCadence = nil
        dfaAlpha1 = nil
        avnn = nil
        sdnn = nil
        rmssd = nil
        pnn50 = nil
        
        powerSamples.removeAll()
        rolling30sPower.removeAll()
        hrSamples.removeAll()
        cadenceSamples.removeAll()
        hrHistory.removeAll()
        powerHistory.removeAll()
        balanceHistory.removeAll()
        hrvEngine.reset()
    }
}
