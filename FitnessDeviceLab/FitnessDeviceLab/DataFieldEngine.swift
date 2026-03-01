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
    
    private var powerSamples: [Int] = []
    private var rolling30sPower: [Double] = []
    private var hrSamples: [Int] = []
    private var cadenceSamples: [Int] = []
    
    private var timerCancellable: AnyCancellable?
    
    public var userFTP: Double = 250.0 // Default FTP
    
    public init() {}
    
    public func start(getPower: @escaping () -> Int?, getHR: @escaping () -> Int?, getCadence: @escaping () -> Int?, getAltitude: @escaping () -> Double?) {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick(power: getPower(), hr: getHR(), cadence: getCadence(), altitude: getAltitude())
            }
    }
    
    public func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func tick(power: Int?, hr: Int?, cadence: Int?, altitude: Double?) {
        if let p = power {
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
            hrSamples.append(h)
            maxHeartRate = max(maxHeartRate ?? 0, h)
            avgHeartRate = Double(hrSamples.reduce(0, +)) / Double(hrSamples.count)
        }
        
        if let c = cadence {
            cadenceSamples.append(c)
            maxCadence = max(maxCadence ?? 0, c)
            avgCadence = Double(cadenceSamples.reduce(0, +)) / Double(cadenceSamples.count)
        }
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
        powerSamples.removeAll()
        rolling30sPower.removeAll()
        hrSamples.removeAll()
        cadenceSamples.removeAll()
    }
}
