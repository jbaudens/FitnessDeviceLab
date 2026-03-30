import Foundation
import Observation

@Observable @MainActor
public class SessionRecorder {
    // MARK: - Active Logical Sources (Concrete Types for SwiftUI Picker Compatibility)
    public var hrSource: HeartRateSensor?
    public var powerSource: PowerSensor?
    public var cadenceSource: CadenceSensor?
    
    @ObservationIgnored
    public var hasAnySensor: Bool {
        hrSource != nil || powerSource != nil || cadenceSource != nil
    }
    
    public var isRecording: Bool = false
    
    public var trackpoints: [Trackpoint] = []
    public var latestPoint: Trackpoint?
    public let engine: DataFieldEngine
    
    private let settings: SettingsProvider
    
    public init(settings: SettingsProvider) {
        self.settings = settings
        self.engine = DataFieldEngine(settings: settings)
    }
    
    public func prepare() {
        trackpoints.removeAll()
        latestPoint = nil
        engine.reset()
    }
    
    public func pulse(time: Date, altitude: Double?, rrIntervals: [Double], lapStartTime: Date?) {
        let pt = Trackpoint(
            time: time,
            hr: hrSource?.heartRate,
            power: powerSource?.cyclingPower,
            cadence: cadenceSource?.cadence,
            altitude: altitude,
            powerBalance: powerSource?.powerBalance,
            dfaAlpha1: engine.hrvMetrics.dfaAlpha1,
            rrIntervals: rrIntervals
        )
        
        latestPoint = pt
        if isRecording {
            trackpoints.append(pt)
        }
        
        // Auto-update the engine
        engine.updateMetrics(from: trackpoints, latestPoint: pt, lapStartTime: lapStartTime)
    }
    
    public func stop(metadata: ExportMetadata, laps: [Lap] = []) throws -> [URL] {
        // Only export if we have at least one valid sensor assigned
        guard hrSource != nil || powerSource != nil || cadenceSource != nil else {
            return []
        }

        // and we actually recorded some sample data (at least one valid sample)
        guard trackpoints.contains(where: { $0.hr != nil || $0.power != nil }) else {
            throw AppError.export(.noDataToExport)
        }

        var files: [URL] = []

        let tcxExporter = TCXExporter()
        if let tcx = try? tcxExporter.encode(metadata: metadata, trackpoints: trackpoints, userWeight: settings.userWeight) {
            files.append(tcx)
        }

        let fitEncoder = FitEncoder()
        do {
            let fitData = try fitEncoder.encode(
                trackpoints: trackpoints,
                laps: laps,
                hrSource: hrSource,
                powerSource: powerSource,
                userFTP: settings.userFTP,
                userWeight: settings.userWeight
            )
            let startTime = trackpoints.first?.time ?? Date()
            let filename = FileNameGenerator.generate(metadata: metadata, startTime: startTime, extension: "fit")
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(filename)
            
            try fitData.write(to: fileURL, options: .atomic)
            files.append(fileURL)
        } catch {
            // Route the FIT error through the AppError system instead of swallowing it
            throw AppError.export(.failedToGenerate("FIT Encoding Error: \(error.localizedDescription)"))
        }

        return files
    }
}
