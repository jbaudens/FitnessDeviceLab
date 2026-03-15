import Foundation
import Observation

@Observable @MainActor
public class SessionRecorder {
    // MARK: - Active Logical Sources (Concrete Types for SwiftUI Picker Compatibility)
    public var hrSource: HeartRateSensor?
    public var powerSource: PowerSensor?
    public var cadenceSource: CadenceSensor?
    
    public var isRecording: Bool = false
    
    public var trackpoints: [Trackpoint] = []
    public var latestPoint: Trackpoint?
    
    private let settings: SettingsProvider
    
    public init(settings: SettingsProvider) {
        self.settings = settings
    }
    
    public func prepare() {
        trackpoints.removeAll()
    }
    
    public func stop(label: String, laps: [Lap] = []) -> [URL] {
        var files: [URL] = []
        
        let tcxExporter = TCXExporter()
        if let tcx = tcxExporter.encode(label: label, trackpoints: trackpoints, userWeight: settings.userWeight) {
            files.append(tcx)
        }
        
        let fitEncoder = FitEncoder()
        if let fitData = fitEncoder.encode(
            trackpoints: trackpoints,
            laps: laps,
            hrSource: hrSource,
            powerSource: powerSource,
            userFTP: settings.userFTP,
            userWeight: settings.userWeight
        ) {
            let formatter = ISO8601DateFormatter()
            let safeDate = formatter.string(from: trackpoints.first?.time ?? Date()).replacingOccurrences(of: ":", with: "-")
            let filename = "Workout_\(label.replacingOccurrences(of: " ", with: "_"))_\(safeDate).fit"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? fitData.write(to: tempURL)
            files.append(tempURL)
        }
        
        return files
    }
    
    public func recordPoint(time: Date, altitude: Double?, rrIntervals: [Double]? = nil) {
        let rrThisSecond = rrIntervals ?? hrSource?.latestRRIntervals ?? []
        
        let pt = Trackpoint(
            time: time,
            hr: hrSource?.heartRate,
            power: powerSource?.cyclingPower,
            cadence: cadenceSource?.cadence,
            altitude: altitude,
            powerBalance: powerSource?.powerBalance,
            rrIntervals: rrThisSecond
        )
        
        latestPoint = pt
        if isRecording {
            trackpoints.append(pt)
        }
        
        // Only clear if we didn't receive them as a parameter (caller handles it)
        if rrIntervals == nil {
            hrSource?.latestRRIntervals.removeAll()
        }
    }
}
