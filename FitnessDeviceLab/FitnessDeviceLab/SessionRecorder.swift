import Foundation
import Combine

nonisolated public struct Trackpoint: Identifiable {
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

public struct Lap: Identifiable {
    public let id = UUID()
    public let index: Int
    public let startTime: Date
    public var endTime: Date?
    public let type: WorkoutStepType
    
    public var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

@MainActor
public class SessionRecorder: ObservableObject {
    var hrDevice: DiscoveredPeripheral?
    var powerDevice: DiscoveredPeripheral?
    
    @Published public var trackpoints: [Trackpoint] = []
    
    private var rrCancellable: AnyCancellable?
    private var pendingRRIntervals: [Double] = []
    
    func prepare() {
        trackpoints.removeAll()
        pendingRRIntervals.removeAll()
        setupRRWatcher()
    }
    
    private func setupRRWatcher() {
        rrCancellable = hrDevice?.$latestRRIntervals
            .receive(on: RunLoop.main)
            .sink { [weak self] intervals in
                self?.pendingRRIntervals.append(contentsOf: intervals)
            }
    }
    
    func stop(label: String, laps: [Lap] = []) -> [URL] {
        rrCancellable?.cancel()
        rrCancellable = nil
        
        var files: [URL] = []
        if let tcx = generateTCX(label: label) { files.append(tcx) }
        if let fit = generateFIT(label: label, laps: laps) { files.append(fit) }
        return files
    }
    
    private func generateFIT(label: String, laps: [Lap]) -> URL? {
        let encoder = FitEncoder()
        let data = encoder.encode(trackpoints: trackpoints, laps: laps)
        
        let formatter = ISO8601DateFormatter()
        let safeDate = formatter.string(from: trackpoints.first?.time ?? Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "Workout_\(label)_\(safeDate).fit"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        return tempURL
    }
    
    func recordPoint(time: Date, altitude: Double?) {
        let rrThisSecond = pendingRRIntervals
        pendingRRIntervals.removeAll()
        
        let pt = Trackpoint(
            time: time,
            hr: hrDevice?.heartRate,
            power: powerDevice?.cyclingPower,
            cadence: powerDevice?.cadence,
            altitude: altitude,
            powerBalance: powerDevice?.powerBalance,
            rrIntervals: rrThisSecond
        )
        
        trackpoints.append(pt)
    }
    
    private func generateTCX(label: String) -> URL? {
        guard !trackpoints.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        let startTimeStr = formatter.string(from: trackpoints.first!.time)
        let totalTime = trackpoints.last!.time.timeIntervalSince(trackpoints.first!.time)
        
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<TrainingCenterDatabase xmlns=\"http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2\" xmlns:ns3=\"http://www.garmin.com/xmlschemas/ActivityExtension/v2\">\n"
        xml += "  <Activities>\n"
        xml += "    <Activity Sport=\"Biking\">\n"
        xml += "      <Id>\(startTimeStr)</Id>\n"
        xml += "      <Lap StartTime=\"\(startTimeStr)\">\n"
        xml += "        <TotalTimeSeconds>\(Int(totalTime))</TotalTimeSeconds>\n"
        xml += "        <Track>\n"
        
        for pt in trackpoints {
            xml += "          <Trackpoint>\n"
            xml += "            <Time>\(formatter.string(from: pt.time))</Time>\n"
            if let alt = pt.altitude { xml += "            <AltitudeMeters>\(alt)</AltitudeMeters>\n" }
            if let hr = pt.hr { xml += "            <HeartRateBpm><Value>\(hr)</Value></HeartRateBpm>\n" }
            if let cad = pt.cadence { xml += "            <Cadence>\(cad)</Cadence>\n" }
            if let pwr = pt.power {
                xml += "            <Extensions>\n"
                xml += "              <ns3:TPX>\n"
                xml += "                <ns3:Watts>\(pwr)</ns3:Watts>\n"
                if let balance = pt.powerBalance {
                    xml += "                <ns3:Value>\(Int(round(balance)))</ns3:Value>\n" // Simplified balance tag
                }
                xml += "              </ns3:TPX>\n"
                xml += "            </Extensions>\n"
            }
            xml += "          </Trackpoint>\n"
        }
        
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
