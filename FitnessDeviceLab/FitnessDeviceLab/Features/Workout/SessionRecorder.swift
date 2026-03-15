import Foundation
import Observation

public struct Trackpoint: Identifiable, Sendable {
    public let id = UUID()
    public let time: Date
    public let hr: Int?
    public let power: Int?
    public let cadence: Int?
    public let altitude: Double?
    public let powerBalance: Double?
    public let rrIntervals: [Double]
    
    public init(time: Date, hr: Int? = nil, power: Int? = nil, cadence: Int? = nil, altitude: Double? = nil, powerBalance: Double? = nil, rrIntervals: [Double] = []) {
        self.time = time
        self.hr = hr
        self.power = power
        self.cadence = cadence
        self.altitude = altitude
        self.powerBalance = powerBalance
        self.rrIntervals = rrIntervals
    }
}

public struct Lap: Identifiable, Sendable {
    public let id = UUID()
    public let index: Int
    public let startTime: Date
    public var endTime: Date?
    public let type: WorkoutStepType
    public var activeDuration: TimeInterval = 0
    
    public var duration: TimeInterval {
        return activeDuration
    }
    
    public init(index: Int, startTime: Date, type: WorkoutStepType) {
        self.index = index
        self.startTime = startTime
        self.type = type
    }
}

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
        if let tcx = generateTCX(label: label) { files.append(tcx) }
        if let fit = generateFIT(label: label, laps: laps) { files.append(fit) }
        return files
    }
    
    private func generateFIT(label: String, laps: [Lap]) -> URL? {
        let encoder = FitEncoder()
        let ftp = settings.userFTP
        let weight = settings.userWeight
        
        guard let data = encoder.encode(
            trackpoints: trackpoints, 
            laps: laps, 
            hrSource: hrSource, 
            powerSource: powerSource, 
            userFTP: ftp, 
            userWeight: weight
        ) else { return nil }
        
        let formatter = ISO8601DateFormatter()
        let safeDate = formatter.string(from: trackpoints.first?.time ?? Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "Workout_\(label)_\(safeDate).fit"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        return tempURL
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
    
    private func generateTCX(label: String) -> URL? {
        guard !trackpoints.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        let startTimeStr = formatter.string(from: trackpoints.first!.time)
        let totalTime = trackpoints.last!.time.timeIntervalSince(trackpoints.first!.time)
        let totalWeight = settings.userWeight + 6.8
        
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<TrainingCenterDatabase xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\" xmlns:ns3=\"http://www.garmin.com/xmlschemas/ActivityExtension/v2\">\n"
        xml += "  <Activities>\n"
        xml += "    <Activity Sport=\"Biking\">\n"
        xml += "      <Id>\(startTimeStr)</Id>\n"
        xml += "      <Lap StartTime=\"\(startTimeStr)\">\n"
        xml += "        <TotalTimeSeconds>\(Int(totalTime))</TotalTimeSeconds>\n"
        
        var totalDistance: Double = 0
        var xmlPoints = ""
        for i in 0..<trackpoints.count {
            let pt = trackpoints[i]
            let power = Double(pt.power ?? 0)
            let speed = PhysicsUtilities.estimateSpeed(power: power, totalWeight: totalWeight)
            
            if i > 0 {
                let dt = pt.time.timeIntervalSince(trackpoints[i-1].time)
                if dt > 0 && dt < 10 {
                    totalDistance += speed * dt
                }
            }
            
            xmlPoints += "          <Trackpoint>\n"
            xmlPoints += "            <Time>\(formatter.string(from: pt.time))</Time>\n"
            let distStr = String(format: "%.2f", totalDistance)
            xmlPoints += "            <DistanceMeters>\(distStr)</DistanceMeters>\n"
            if let alt = pt.altitude { xmlPoints += "            <AltitudeMeters>\(alt)</AltitudeMeters>\n" }
            if let hr = pt.hr { xmlPoints += "            <HeartRateBpm><Value>\(hr)</Value></HeartRateBpm>\n" }
            if let cad = pt.cadence { xmlPoints += "            <Cadence>\(cad)</Cadence>\n" }
            
            xmlPoints += "            <Extensions>\n"
            xmlPoints += "              <ns3:TPX>\n"
            let speedStr = String(format: "%.3f", speed)
            xmlPoints += "                <ns3:Speed>\(speedStr)</ns3:Speed>\n"
            if let pwr = pt.power {
                xmlPoints += "                <ns3:Watts>\(pwr)</ns3:Watts>\n"
            }
            if let balance = pt.powerBalance {
                xmlPoints += "                <ns3:Value>\(Int(round(balance)))</ns3:Value>\n"
            }
            xmlPoints += "              </ns3:TPX>\n"
            xmlPoints += "            </Extensions>\n"
            xmlPoints += "          </Trackpoint>\n"
        }
        
        let totalDistStr = String(format: "%.2f", totalDistance)
        xml += "        <DistanceMeters>\(totalDistStr)</DistanceMeters>\n"
        xml += "        <Track>\n"
        xml += xmlPoints
        xml += "        </Track>\n"
        xml += "      </Lap>\n"
        xml += "    </Activity>\n"
        xml += "  </Activities>\n"
        xml += "</TrainingCenterDatabase>"
        
        let safeDate = formatter.string(from: trackpoints.first!.time).replacingOccurrences(of: ":", with: "-")
        let filename = "Workout_\(label)_\(safeDate).tcx"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? xml.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}
