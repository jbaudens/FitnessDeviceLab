import Foundation
import Observation

@Observable
public class SettingsViewModel {
    private let settings: SettingsManager
    
    // UI Local State
    public var userFTP: String = ""
    public var userWeight: String = ""
    public var maxHR: String = ""
    public var userLTHR: String = ""
    public var ftpAltitude: String = ""
    public var altitudeOverride: String = ""
    public var useAltitudeOverride: Bool = false
    
    public init(settings: SettingsManager) {
        self.settings = settings
        syncFromSettings()
    }
    
    public func syncFromSettings() {
        userFTP = String(format: "%.0f", settings.userFTP)
        userWeight = String(format: "%.1f", settings.userWeight)
        maxHR = String(format: "%d", settings.maxHR)
        userLTHR = String(format: "%d", settings.userLTHR)
        ftpAltitude = String(format: "%.0f", settings.ftpAltitude)
        
        if let over = settings.altitudeOverride {
            altitudeOverride = String(format: "%.0f", over)
            useAltitudeOverride = true
        } else {
            altitudeOverride = ""
            useAltitudeOverride = false
        }
    }
    
    public func updateFTP(_ newValue: String) {
        if let val = Double(newValue) {
            settings.setUserFTP(val)
        }
    }
    
    public func updateWeight(_ newValue: String) {
        if let val = Double(newValue) {
            settings.setUserWeight(val)
        }
    }
    
    public func updateMaxHR(_ newValue: String) {
        if let val = Int(newValue) {
            settings.setMaxHR(val)
        }
    }
    
    public func updateUserLTHR(_ newValue: String) {
        if let val = Int(newValue) {
            settings.setUserLTHR(val)
        }
    }
    
    public func updateFTPAltitude(_ newValue: String) {
        if let val = Double(newValue) {
            settings.setFTPAltitude(val)
        }
    }
    
    public func updateAltitudeOverrideToggle(_ isOn: Bool) {
        if !isOn {
            settings.setAltitudeOverride(nil)
        } else if let val = Double(altitudeOverride) {
            settings.setAltitudeOverride(val)
        }
    }
    
    public func updateAltitudeOverrideValue(_ newValue: String) {
        if let val = Double(newValue) {
            settings.setAltitudeOverride(val)
        }
    }
    
    public func resetToDefaults() {
        settings.setUserFTP(250)
        settings.setUserWeight(75)
        settings.setMaxHR(190)
        settings.setUserLTHR(170)
        settings.setFTPAltitude(0)
        settings.setAltitudeOverride(nil)
        syncFromSettings()
    }
}
