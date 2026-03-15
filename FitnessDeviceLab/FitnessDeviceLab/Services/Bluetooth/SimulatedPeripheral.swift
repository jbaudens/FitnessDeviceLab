import Foundation
import Observation

@Observable @MainActor
public class SimulatedPeripheral: SensorPeripheral, HeartRateProviding, PowerProviding, CadenceProviding, ResistanceControllable {
    public let id: UUID
    public let name: String
    public var isConnected: Bool = true
    
    public var manufacturerName: String? = "FitnessDeviceLab"
    public var modelNumber: String? = "Simulated v1"
    
    public var heartRate: Int?
    public var cyclingPower: Int?
    public var cadence: Int?
    public var powerBalance: Double?
    
    public var latestRRIntervals: [Double] = []
    public var capabilities: Set<DeviceCapability> = [.heartRate, .cyclingPower, .fitnessMachine, .cadence]
    
    private var timer: Timer?
    private var startTime = Date()
    
    public init(name: String = "Virtual Bike") {
        self.id = UUID()
        self.name = name
        startSimulation()
    }
    
    public func startSimulation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateValues()
            }
        }
    }
    
    private func updateValues() {
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Generate some realistic-ish drifting data
        heartRate = 120 + Int(20 * sin(elapsed / 60.0)) + Int.random(in: -2...2)
        cyclingPower = 200 + Int(50 * sin(elapsed / 30.0)) + Int.random(in: -10...10)
        cadence = 85 + Int(5 * sin(elapsed / 45.0)) + Int.random(in: -2...2)
        powerBalance = 50.0 + Double.random(in: -1.0...1.0)
        
        if let hr = heartRate {
            let rr = 60.0 / Double(hr)
            latestRRIntervals = [rr + Double.random(in: -0.01...0.01)]
        }
    }
    
    public func setTargetPower(_ watts: Int) {
        print("Simulated Trainer: Target Power set to \(watts)W")
    }
    
    public func setResistanceLevel(_ level: Double) {
        print("Simulated Trainer: Resistance set to \(level)%")
    }
}
