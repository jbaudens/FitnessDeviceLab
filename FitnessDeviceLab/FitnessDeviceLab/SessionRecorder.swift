import Foundation
import Combine

nonisolated public struct Trackpoint: Identifiable {
    public let id = UUID()
    public let time: Date
    public let hr: Int?
    public let power: Int?
    public let cadence: Int?
    public let rrIntervals: [Double]
    
    public init(time: Date, hr: Int? = nil, power: Int? = nil, cadence: Int? = nil, rrIntervals: [Double] = []) {
        self.time = time
        self.hr = hr
        self.power = power
        self.cadence = cadence
        self.rrIntervals = rrIntervals
    }
}

@MainActor
class SessionRecorder: ObservableObject {
    var hrDevice: DiscoveredPeripheral?
    var powerDevice: DiscoveredPeripheral?
    
    @Published public var trackpoints: [Trackpoint] = []
    @Published public var lastUpdate = Date()
    
    // Published results of stateless calculations
    @Published public var calculatedMetrics = CalculatedMetrics()
    @Published public var hrvMetrics = HRVMetrics()
    
    private var timerCancellable: AnyCancellable?
    private var rrCancellable: AnyCancellable?
    
    // Internal buffer to collect RR intervals between 1Hz ticks
    private var pendingRRIntervals: [Double] = []
    
    func start() {
        trackpoints.removeAll()
        pendingRRIntervals.removeAll()
        calculatedMetrics = CalculatedMetrics()
        hrvMetrics = HRVMetrics()
        lastUpdate = Date()
        
        setupRRWatcher()
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.recordPoint()
                }
            }
    }
    
    private func setupRRWatcher() {
        rrCancellable = hrDevice?.$latestRRIntervals
            .receive(on: RunLoop.main) // Explicitly ensure we append on Main Thread
            .sink { [weak self] intervals in
                guard let self = self, !intervals.isEmpty else { return }
                // Collect intervals into the pending buffer
                self.pendingRRIntervals.append(contentsOf: intervals)
            }
    }
    
    func stop(label: String) -> URL? {
        timerCancellable?.cancel()
        timerCancellable = nil
        rrCancellable?.cancel()
        rrCancellable = nil
        return generateTCX(label: label)
    }
    
    private func recordPoint() {
        let now = Date()
        
        // Take the collected RR intervals and clear the buffer
        let rrThisSecond = pendingRRIntervals
        pendingRRIntervals.removeAll()
        
        let pt = Trackpoint(
            time: now,
            hr: hrDevice?.heartRate,
            power: powerDevice?.cyclingPower,
            cadence: powerDevice?.cadence,
            rrIntervals: rrThisSecond
        )
        
        if pt.hr != nil || pt.power != nil || pt.cadence != nil || !pt.rrIntervals.isEmpty {
            trackpoints.append(pt)
            
            // 1. Calculate Standard Metrics (Fast)
            self.calculatedMetrics = DataFieldEngine.calculate(
                from: trackpoints,
                userFTP: SettingsManager.shared.userFTP,
                currentAltitude: LocationManager.shared.currentAltitude
            )
            
            // 2. Calculate HRV Metrics (Potentially Heavy)
            // Perform this on a background task to keep the UI responsive
            let allRR = trackpoints.flatMap { $0.rrIntervals }
            let windowRR = Array(allRR.suffix(600))
            
            Task.detached(priority: .userInitiated) {
                let newHRV = HRVEngine.calculateMetrics(rawRRIntervals: windowRR)
                await MainActor.run {
                    self.hrvMetrics = newHRV
                }
            }
            
            lastUpdate = now
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
