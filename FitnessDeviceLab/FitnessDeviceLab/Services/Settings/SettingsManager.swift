import Foundation
import Observation

/// A read-only interface for application settings.
public protocol SettingsProvider: AnyObject, Observation.Observable {
    var userFTP: Double { get }
    var maxHR: Int { get }
    var userLTHR: Int { get }
    var altitudeOverride: Double? { get }
    var userWeight: Double { get }
    var ftpAltitude: Double { get }
    var metricsSettings: MetricsSettings { get }
}

@Observable
public class SettingsManager: SettingsProvider {
    private let defaults = UserDefaults.standard

    public private(set) var userFTP: Double {
        didSet { defaults.set(userFTP, forKey: "userFTP") }
    }

    public private(set) var maxHR: Int {
        didSet { defaults.set(maxHR, forKey: "maxHeartRate") }
    }

    public private(set) var userLTHR: Int {
        didSet { defaults.set(userLTHR, forKey: "userLTHR") }
    }

    public private(set) var altitudeOverride: Double? {
        didSet { 
            if let val = altitudeOverride {
                defaults.set(val, forKey: "altitudeOverride")
            } else {
                defaults.removeObject(forKey: "altitudeOverride")
            }
        }
    }

    public private(set) var userWeight: Double {
        didSet { defaults.set(userWeight, forKey: "userWeight") }
    }

    public private(set) var ftpAltitude: Double {
        didSet { defaults.set(ftpAltitude, forKey: "ftpAltitude") }
    }

    public var metricsSettings: MetricsSettings {
        MetricsSettings(userFTP: userFTP, userWeight: userWeight, ftpAltitude: ftpAltitude)
    }

    // MARK: - Explicit Setters for UI

    public func setUserFTP(_ value: Double) { userFTP = value }
    public func setMaxHR(_ value: Int) { maxHR = value }
    public func setUserLTHR(_ value: Int) { userLTHR = value }
    public func setAltitudeOverride(_ value: Double?) { altitudeOverride = value }
    public func setUserWeight(_ value: Double) { userWeight = value }
    public func setFTPAltitude(_ value: Double) { ftpAltitude = value }

    public init() {
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
