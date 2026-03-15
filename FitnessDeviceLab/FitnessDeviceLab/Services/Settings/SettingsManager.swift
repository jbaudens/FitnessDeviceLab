import Foundation
import Observation

@Observable
public class SettingsManager {
    public static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    public var userFTP: Double {
        didSet { defaults.set(userFTP, forKey: "userFTP") }
    }
    
    public var maxHR: Int {
        didSet { defaults.set(maxHR, forKey: "maxHeartRate") }
    }
    
    public var userLTHR: Int {
        didSet { defaults.set(userLTHR, forKey: "userLTHR") }
    }
    
    public var altitudeOverride: Double? {
        didSet { 
            if let val = altitudeOverride {
                defaults.set(val, forKey: "altitudeOverride")
            } else {
                defaults.removeObject(forKey: "altitudeOverride")
            }
        }
    }
    
    public var userWeight: Double {
        didSet { defaults.set(userWeight, forKey: "userWeight") }
    }
    
    public var ftpAltitude: Double {
        didSet { defaults.set(ftpAltitude, forKey: "ftpAltitude") }
    }
    
    public var metricsSettings: MetricsSettings {
        MetricsSettings(userFTP: userFTP, userWeight: userWeight, ftpAltitude: ftpAltitude)
    }
    
    private init() {
        let savedFTP = defaults.double(forKey: "userFTP")
        self.userFTP = savedFTP > 0 ? savedFTP : 250.0
        
        let savedHR = defaults.integer(forKey: "maxHeartRate")
        self.maxHR = savedHR > 0 ? savedHR : 190
        
        let savedLTHR = defaults.integer(forKey: "userLTHR")
        self.userLTHR = savedLTHR > 0 ? savedLTHR : 170
        
        let savedAlt = defaults.object(forKey: "altitudeOverride") as? Double
        self.altitudeOverride = savedAlt
        
        let savedWeight = defaults.double(forKey: "userWeight")
        self.userWeight = savedWeight > 0 ? savedWeight : 75.0
        
        let savedFTPAlt = defaults.double(forKey: "ftpAltitude")
        self.ftpAltitude = savedFTPAlt // Can be 0
    }
}
