import Foundation
import Observation
import Testing
@testable import FitnessDeviceLab

@Observable
class MockSettingsProvider: SettingsProvider {
    var userFTP: Double = 200.0
    var maxHR: Int = 190
    var userLTHR: Int = 170
    var altitudeOverride: Double? = nil
    var userWeight: Double = 75.0
    var ftpAltitude: Double = 0.0
    var metricsSettings: MetricsSettings {
        MetricsSettings(userFTP: userFTP, userWeight: userWeight, ftpAltitude: ftpAltitude)
    }
    
    // Explicit setters for protocol if needed (already in SettingsManager but added here for completeness if used)
    func setUserFTP(_ value: Double) { userFTP = value }
    func setMaxHR(_ value: Int) { maxHR = value }
    func setUserLTHR(_ value: Int) { userLTHR = value }
    func setAltitudeOverride(_ value: Double?) { altitudeOverride = value }
    func setUserWeight(_ value: Double) { userWeight = value }
    func setFTPAltitude(_ value: Double) { ftpAltitude = value }
}

class MockLocationProvider: LocationProvider {
    var currentAltitude: Double? = 100.0
}

@Observable
class MockTrainer: NSObject, SensorPeripheral, ResistanceControllable {
    let id = UUID()
    let name = "Mock Trainer"
    var isConnected = true
    var manufacturerName: String? = "Mock"
    var modelNumber: String? = "Mock-1"
    var capabilities: Set<DeviceCapability> = [.cyclingPower, .fitnessMachine]
    
    var supportsPowerControl: Bool { true }
    var supportsResistanceControl: Bool { true }
    
    var heartRate: Int? = nil
    var cyclingPower: Int? = 0
    var cadence: Int? = 0
    var powerBalance: Double? = 50.0
    var latestRRIntervals: [Double] = []
    
    var lastSetTargetPower: Int?
    var lastSetResistanceLevel: Double?

    func setTargetPower(_ watts: Int) {
        lastSetTargetPower = watts
    }
    
    func setResistanceLevel(_ level: Double) {
        lastSetResistanceLevel = level
    }
}
