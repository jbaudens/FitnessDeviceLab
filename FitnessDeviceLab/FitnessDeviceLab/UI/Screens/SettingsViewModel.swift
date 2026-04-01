import Foundation
import Observation

@Observable
public class SettingsViewModel {
    public let settings: SettingsManager
    public var useAltitudeOverride: Bool = false
    
    public init(settings: SettingsManager) {
        self.settings = settings
        self.useAltitudeOverride = settings.altitudeOverride != nil
    }
    
    public func updateAltitudeOverrideToggle(_ isOn: Bool) {
        if !isOn {
            settings.setAltitudeOverride(nil)
        } else {
            settings.setAltitudeOverride(settings.altitudeOverride ?? 0)
        }
    }
    
    public func resetToDefaults() {
        settings.setUserFTP(250)
        settings.setUserWeight(75)
        settings.setMaxHR(190)
        settings.setUserLTHR(170)
        settings.setFTPAltitude(0)
        settings.setAltitudeOverride(nil)
        useAltitudeOverride = false
    }
}
