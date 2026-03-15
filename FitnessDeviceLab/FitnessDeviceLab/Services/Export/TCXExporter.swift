import Foundation

/// A TCX (Training Center XML) exporter for activity data.
/// Compatible with Garmin Connect, Strava, and other platforms.
public class TCXExporter {
    
    public init() {}
    
    /// Encodes activity data to a TCX file and returns the URL to the temporary file.
    /// - Parameters:
    ///   - label: A label for the activity (used in filename).
    ///   - trackpoints: The recorded trackpoints.
    ///   - userWeight: User weight for speed estimation.
    /// - Returns: URL of the generated TCX file.
    public func encode(label: String, trackpoints: [Trackpoint], userWeight: Double) -> URL? {
        print("TCXExporter: Encoding \(trackpoints.count) points for \(label)")
        guard !trackpoints.isEmpty else { return nil }
        
        let formatter = ISO8601DateFormatter()
        let startTimeStr = formatter.string(from: trackpoints.first!.time)
        let totalTime = trackpoints.last!.time.timeIntervalSince(trackpoints.first!.time)
        let totalWeight = userWeight + 6.8 // Bike weight offset
        
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
            
            if let alt = pt.altitude {
                xmlPoints += "            <AltitudeMeters>\(alt)</AltitudeMeters>\n"
            }
            
            if let hr = pt.hr {
                xmlPoints += "            <HeartRateBpm><Value>\(hr)</Value></HeartRateBpm>\n"
            }
            
            if let cad = pt.cadence {
                xmlPoints += "            <Cadence>\(cad)</Cadence>\n"
            }
            
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
        let filename = "Workout_\(label.replacingOccurrences(of: " ", with: "_"))_\(safeDate).tcx"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try xml.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write TCX file: \(error)")
            return nil
        }
    }
}
