import Foundation
import Combine

struct Trackpoint {
    let time: Date
    let hr: Int?
    let power: Int?
    let cadence: Int?
}

class SessionRecorder {
    var hrDevice: DiscoveredPeripheral?
    var powerDevice: DiscoveredPeripheral?
    
    private var trackpoints: [Trackpoint] = []
    private var timerCancellable: AnyCancellable?
    
    func start() {
        trackpoints.removeAll()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recordPoint()
            }
    }
    
    func stop(label: String) -> URL? {
        timerCancellable?.cancel()
        timerCancellable = nil
        return generateTCX(label: label)
    }
    
    private func recordPoint() {
        // Sample currently published values from the peripherals
        let pt = Trackpoint(
            time: Date(),
            hr: hrDevice?.heartRate,
            power: powerDevice?.cyclingPower,
            cadence: powerDevice?.cadence
        )
        // Only record if we actually have some data
        if pt.hr != nil || pt.power != nil || pt.cadence != nil {
            trackpoints.append(pt)
        }
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
            if let hr = pt.hr {
                xml += "            <HeartRateBpm><Value>\(hr)</Value></HeartRateBpm>\n"
            }
            if let cad = pt.cadence {
                xml += "            <Cadence>\(cad)</Cadence>\n"
            }
            if let pwr = pt.power {
                xml += "            <Extensions>\n"
                xml += "              <ns3:TPX>\n"
                xml += "                <ns3:Watts>\(pwr)</ns3:Watts>\n"
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
        
        do {
            try xml.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write TCX: \(error)")
            return nil
        }
    }
}
