import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    @Published var userFTP: Double {
        didSet { defaults.set(userFTP, forKey: "userFTP") }
    }
    
    @Published var maxHR: Int {
        didSet { defaults.set(maxHR, forKey: "maxHeartRate") }
    }
    
    @Published var altitudeOverride: Double? {
        didSet { 
            if let val = altitudeOverride {
                defaults.set(val, forKey: "altitudeOverride")
            } else {
                defaults.removeObject(forKey: "altitudeOverride")
            }
        }
    }
    
    @Published var userWeight: Double {
        didSet { defaults.set(userWeight, forKey: "userWeight") }
    }
    
    @Published var ftpAltitude: Double {
        didSet { defaults.set(ftpAltitude, forKey: "ftpAltitude") }
    }
    
    private init() {
        let savedFTP = defaults.double(forKey: "userFTP")
        self.userFTP = savedFTP > 0 ? savedFTP : 250.0
        
        let savedHR = defaults.integer(forKey: "maxHeartRate")
        self.maxHR = savedHR > 0 ? savedHR : 190
        
        let savedAlt = defaults.object(forKey: "altitudeOverride") as? Double
        self.altitudeOverride = savedAlt
        
        let savedWeight = defaults.double(forKey: "userWeight")
        self.userWeight = savedWeight > 0 ? savedWeight : 75.0
        
        let savedFTPAlt = defaults.double(forKey: "ftpAltitude")
        self.ftpAltitude = savedFTPAlt // Can be 0
    }
}
