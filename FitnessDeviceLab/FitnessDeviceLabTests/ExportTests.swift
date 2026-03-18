import Testing
import Foundation
import XCTest // Still needed for XCTUnwrap if we want it, but we can use #expect
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
        let url = try #require(exporter.encode(metadata: metadata, trackpoints: trackpoints, userWeight: userWeight))
        
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
        let data = try #require(encoder.encode(
            trackpoints: trackpoints,
            laps: [],
            hrSource: nil,
            powerSource: nil,
            userFTP: 250,
            userWeight: userWeight
        ))
        
        #expect(data.count > 100)
        
        if data.count > 12 {
            let signature = String(data: data.subdata(in: 8..<12), encoding: .ascii)
            #expect(signature == ".FIT")
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
    }
}
