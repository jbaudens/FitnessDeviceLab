import Testing
import Foundation
import XCTest // Still needed for XCTUnwrap if we want it, but we can use #expect
import FITSwiftSDK
@testable import FitnessDeviceLab

struct ExportTests {
    
    let userWeight = 70.0
    
    private func createTrackpoints() -> [Trackpoint] {
        var trackpoints: [Trackpoint] = []
        let startTime = Date()
        for i in 0..<60 {
            let pt = Trackpoint(
                time: startTime.addingTimeInterval(Double(i)),
                hr: 140 + (i % 5),
                power: 200 + (i % 10),
                cadence: 90,
                altitude: 100.0 + Double(i) * 0.1,
                powerBalance: 50.0 + (i % 2 == 0 ? 1.0 : -1.0)
            )
            trackpoints.append(pt)
        }
        return trackpoints
    }
    
    @Test func tcxExport() throws {
        let trackpoints = createTrackpoints()
        let exporter = TCXExporter()
        let metadata = ExportMetadata(workoutName: "Test Workout")
        let url = try exporter.encode(metadata: metadata, trackpoints: trackpoints, userWeight: userWeight)
        
        #expect(url.lastPathComponent.contains("Test_Workout"))
        #expect(FileManager.default.fileExists(atPath: url.path))
        
        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("<TrainingCenterDatabase"))
        #expect(content.contains("<Activity Sport=\"Biking\">"))
        #expect(content.contains("<Trackpoint>"))
        #expect(content.contains("<HeartRateBpm>"))
        #expect(content.contains("<ns3:Speed>"))
        #expect(content.contains("<ns3:Watts>"))
        
        #expect(content.contains("<DistanceMeters>"))
        let regex = try NSRegularExpression(pattern: "<DistanceMeters>[1-9]", options: [])
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
        #expect(matches.count > 0)
    }
    
    @Test func fitExport() throws {
        let trackpoints = createTrackpoints()
        let encoder = FitEncoder()
        
        // Mock a power source to satisfy the new SessionRecorder data checks if needed
        // (though this test calls FitEncoder directly, let's keep it robust)
        let data = try encoder.encode(
            trackpoints: trackpoints,
            laps: [],
            hrSource: nil,
            powerSource: nil,
            userFTP: 250,
            userWeight: userWeight
        )
        
        #expect(data.count > 100)
        
        if data.count > 12 {
            let signature = String(data: data.subdata(in: 8..<12), encoding: .ascii)
            #expect(signature == ".FIT")
        }
    }
    
    @Test @MainActor func sessionRecorderStop() throws {
        let settings = MockSettingsProvider()
        let recorder = SessionRecorder(settings: settings)
        let startTime = Date()
        
        let mockTrainer = MockTrainer()
        mockTrainer.capabilities.insert(.heartRate)
        mockTrainer.heartRate = 140
        
        // Mock a sensor to pass the guard
        recorder.hrSource = HeartRateSensor(peripheral: mockTrainer)
        recorder.isRecording = true
        
        // Add some data
        for i in 0..<10 {
            recorder.pulse(time: startTime.addingTimeInterval(Double(i)), altitude: 100, rrIntervals: [], lapStartTime: startTime)
        }
        
        let metadata = ExportMetadata(workoutName: "Recorder Test")
        let files = try recorder.stop(metadata: metadata)
        
        #expect(files.count >= 1)
        for file in files {
            #expect(FileManager.default.fileExists(atPath: file.path))
            print("DEBUG: Verified file exists at \(file.path)")
        }
    }
}

struct FileNameGeneratorTests {
    @Test func testFileNameGeneration() {
        let startTime = Date(timeIntervalSince1970: 1710792000) // 2024-03-18 20:00:00 UTC
        
        // 1. Full Metadata
        let meta1 = ExportMetadata(workoutName: "Threshold Intervals", powerMeterName: "Quarq", hrmName: "HRM-Dual")
        let name1 = FileNameGenerator.generate(metadata: meta1, startTime: startTime, extension: "fit")
        #expect(name1 == "Threshold_Intervals_Quarq_HRM-Dual_2024-03-18T20-00-00.fit")
        
        // 2. Minimal Metadata
        let meta2 = ExportMetadata(workoutName: "FreeRide")
        let name2 = FileNameGenerator.generate(metadata: meta2, startTime: startTime, extension: "tcx")
        #expect(name2 == "FreeRide_2024-03-18T20-00-00.tcx")
        
        // 3. Metadata with spaces
        let meta3 = ExportMetadata(workoutName: "Long Ride", powerMeterName: "Stages Power", hrmName: nil)
        let name3 = FileNameGenerator.generate(metadata: meta3, startTime: startTime, extension: "fit")
        #expect(name3 == "Long_Ride_Stages_Power_2024-03-18T20-00-00.fit")
        
        // 4. Metadata with slashes
        let meta4 = ExportMetadata(workoutName: "VT1/VT2 Ramp")
        let name4 = FileNameGenerator.generate(metadata: meta4, startTime: startTime, extension: "fit")
        #expect(name4 == "VT1-VT2_Ramp_2024-03-18T20-00-00.fit")
    }
}

@MainActor
struct AnalysisTests {
    @Test func analyzeComparisonFiles() throws {
        let fileManager = FileManager.default
        let folderPath = "/Users/jbaudens/FitnessDeviceLab/ComparisonFitFile"
        let files = try fileManager.contentsOfDirectory(atPath: folderPath).filter { $0.hasSuffix(".fit") }
        
        struct Record {
            let timestamp: Date
            let power: Double
            let hr: Double
        }
        
        func getRecords(for fileName: String) throws -> [Record] {
            let fileURL = URL(fileURLWithPath: folderPath).appendingPathComponent(fileName)
            let data = try Data(contentsOf: fileURL)
            let decoder = FITSwiftSDK.Decoder(stream: InputStream(data: data))
            
            class TestListener: MesgListener {
                var records = [Record]()
                func onMesg(_ mesg: Mesg) throws {
                    if let r = mesg as? RecordMesg, let ts = r.getTimestamp()?.date {
                        records.append(Record(
                            timestamp: ts,
                            power: Double(r.getPower() ?? 0),
                            hr: Double(r.getHeartRate() ?? 0)
                        ))
                    }
                }
            }
            let listener = TestListener()
            decoder.addMesgListener(listener)
            try decoder.read(decodeMode: .normal)
            return listener.records
        }
        
        print("DEBUG: Files found in folder: \(files)")
        guard files.count >= 2 else { 
            print("ERROR: Expected at least 2 FIT files, found \(files.count)")
            return 
        }
        
        // Ensure consistent ordering (Stages vs Vector 3)
        guard let fileA = files.first(where: { $0.contains("Stages") }),
              let fileB = files.first(where: { $0.contains("V3") }) else {
            print("ERROR: Could not find both Stages and Vector 3 files")
            return
        }
        
        print("DEBUG: Analyzing \(fileA) vs \(fileB)")
        let recordsA = try getRecords(for: fileA)
        let recordsB = try getRecords(for: fileB)
        print("DEBUG: Record counts: A=\(recordsA.count), B=\(recordsB.count)")
        
        // Map by timestamp for alignment
        var mapB = [Date: Record]()
        for r in recordsB { mapB[r.timestamp] = r }
        
        print("\n=== HIGH-RESOLUTION POWER ANALYSIS (Stages vs Vector 3) ===")
        
        struct DeltaStats {
            var count: Int = 0
            var sumDelta: Double = 0
            var sumPct: Double = 0
        }
        
        var bins: [Int: DeltaStats] = [:] // Power bins in 50W increments
        
        for rA in recordsA {
            if let rB = mapB[rA.timestamp], rA.power > 20 {
                let bin = Int(rA.power / 50) * 50
                var stats = bins[bin] ?? DeltaStats()
                let delta = rA.power - rB.power
                stats.count += 1
                stats.sumDelta += delta
                stats.sumPct += (delta / rA.power) * 100.0
                bins[bin] = stats
            }
        }
        
        for bin in bins.keys.sorted() {
            let stats = bins[bin]!
            let avgDelta = stats.sumDelta / Double(stats.count)
            let avgPct = stats.sumPct / Double(stats.count)
            print("Bin \(bin)-\(bin+49)W: AvgDelta=\(String(format: "%.1f", avgDelta))W, AvgPct=\(String(format: "%.1f", avgPct))%, N=\(stats.count)")
        }
        
        print("\n=== PHYSIOLOGICAL TRENDS ===")
        // Look for VT1 crossover (DFA a1 = 0.75)
        // From FDL screenshot, Set A was at 0.83 at 74:34. 
        let samples = recordsA.suffix(600) // Last 10 minutes approx
        if let avgHR = (samples.map({ $0.hr }).reduce(0, +) / Double(samples.count)) as Double?,
           let avgPwr = (samples.map({ $0.power }).reduce(0, +) / Double(samples.count)) as Double? {
            print("Final 10m Average: Power=\(Int(avgPwr))W, HR=\(Int(avgHR))bpm")
        }
    }
}
