import Foundation
import Observation

@Observable @MainActor
public class SimulatedPeripheral: NSObject, SensorPeripheral, HeartRateProviding, PowerProviding, CadenceProviding, ResistanceControllable {
    public let id: UUID
    public let name: String
    public var isConnected: Bool = false
    public var expectedDisconnect: Bool = false
    
    public var manufacturerName: String? = "FitnessDeviceLab"
    public var modelNumber: String? = "Digital Twin v1"
    
    // MARK: - Live Metrics
    public var heartRate: Int? = 60
    public var cyclingPower: Int? = 0
    public var cadence: Int? = 0
    public var powerBalance: Double? = 50.0
    public var latestRRIntervals: [Double] = []
    
    public var supportsPowerControl: Bool { true }
    public var supportsResistanceControl: Bool { true }
    
    public var capabilities: Set<DeviceCapability> = [.heartRate, .cyclingPower, .cadence, .fitnessMachine]
    
    // MARK: - Simulation Internal State
    private var simulationTask: Task<Void, Never>?
    private var internalPower: Double = 0
    private var internalHR: Double = 60
    private var internalCadence: Double = 0
    
    private var commandedTargetPower: Double?
    private var commandedResistance: Double = 40.0
    
    var startTime = Date()
    private let settings: SettingsProvider
    
    public init(name: String, settings: SettingsProvider) {
        self.id = UUID()
        self.name = name
        self.settings = settings
        super.init()
        startSimulation()
    }

    public func startSimulation() {
        // Start a new structured concurrency loop isolated to @MainActor
        simulationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }
                self.updateValues()

                // Sleep for 1 second (1Hz update rate)
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    break
                }
            }
        }
    }

    private func updateValues() {
        guard isConnected else { 
            cyclingPower = 0
            cadence = 0
            return 
        }

        let ftp = settings.userFTP
        let maxHR = Double(settings.maxHR)
        let restHR: Double = 60.0

        // 1. Determine Target Power
        let targetPwr: Double
        if let commanded = commandedTargetPower {
            // ERG Mode behavior
            targetPwr = commanded
            let targetCad = 90.0 + Double.random(in: -2...2)
            internalCadence += (targetCad - internalCadence) * 0.2
        } else {
            // Resistance Mode behavior
            let targetCad = 85.0 + (commandedResistance / 10.0)
            internalCadence += (targetCad - internalCadence) * 0.1
            targetPwr = (commandedResistance / 100.0) * ftp * (internalCadence / 90.0)
        }
        
        // 2. Drift Power (Inertia + Noise)
        internalPower += (targetPwr - internalPower) * 0.3
        let powerJitter = Double.random(in: -5...5) 
        cyclingPower = Int(round(max(0, internalPower + powerJitter)))
        
        // 3. Drift Cadence + Noise
        let cadenceJitter = Double.random(in: -1...1)
        cadence = Int(round(max(0, internalCadence + cadenceJitter)))
        
        // 4. Physiological Coupling (Heart Rate)
        let intensity = internalPower / ftp
        let aerobicCeiling = maxHR * 0.9
        let baseTargetHR = restHR + (aerobicCeiling - restHR) * intensity
        
        let totalElapsed = Date().timeIntervalSince(startTime)
        let driftAmount = min(15.0, (totalElapsed / 600.0) * 5.0) 
        let targetHR = baseTargetHR + driftAmount
        
        let hrChangeRate = (targetHR > internalHR) ? 0.05 : 0.02
        internalHR += (targetHR - internalHR) * hrChangeRate
        
        let hrJitter = Double.random(in: -1...1)
        let rawHR = internalHR + hrJitter
        let cappedHR = min(maxHR + 5, max(restHR, rawHR))
        heartRate = Int(round(cappedHR))
        
        // 5. Secondary Metrics
        powerBalance = 50.0 + Double.random(in: -0.5...0.5)
        if let hr = heartRate, hr > 0 {
            let rr = 60.0 / Double(hr)
            latestRRIntervals = [rr + Double.random(in: -0.005...0.005)]
        }
    }
    
    // MARK: - Control Point Implementation
    
    public func setTargetPower(_ watts: Int) {
        commandedTargetPower = Double(watts)
    }
    
    public func setResistanceLevel(_ level: Double) {
        commandedTargetPower = nil 
        commandedResistance = level
    }
}
