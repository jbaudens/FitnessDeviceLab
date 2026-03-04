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
    
    private init() {
        let savedFTP = defaults.double(forKey: "userFTP")
        self.userFTP = savedFTP > 0 ? savedFTP : 250.0
        
        let savedHR = defaults.integer(forKey: "maxHeartRate")
        self.maxHR = savedHR > 0 ? savedHR : 190
    }
}
