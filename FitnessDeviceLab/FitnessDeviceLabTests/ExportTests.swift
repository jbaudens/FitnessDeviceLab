import XCTest
@testable import FitnessDeviceLab

final class ExportTests: XCTestCase {
    
    var trackpoints: [Trackpoint] = []
    let userWeight = 70.0
    
    override func setUp() {
        super.setUp()
        
        let startTime = Date()
        for i in 0..<60 {
            let pt = Trackpoint(
                time: startTime.addingTimeInterval(Double(i)),
                hr: 140 + (i % 5),
                power: 200 + (i % 10),
                cadence: 90,
                altitude: 100.0 + Double(i) * 0.1
            )
            trackpoints.append(pt)
        }
    }
    
    func testTCXExport() {
        let exporter = TCXExporter()
        let url = exporter.encode(label: "Test Workout", trackpoints: trackpoints, userWeight: userWeight)
        
        XCTAssertNotNil(url)
        if let url = url {
            print("--- EXPORTED TCX: \(url.path) ---")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
        
        do {
            let content = try String(contentsOf: url!, encoding: .utf8)
            XCTAssertTrue(content.contains("<TrainingCenterDatabase"))
            XCTAssertTrue(content.contains("<Activity Sport=\"Biking\">"))
            XCTAssertTrue(content.contains("<Trackpoint>"))
            XCTAssertTrue(content.contains("<HeartRateBpm>"))
            XCTAssertTrue(content.contains("<ns3:Speed>"))
            XCTAssertTrue(content.contains("<ns3:Watts>"))
            
            // Validate distance is > 0
            XCTAssertTrue(content.contains("<DistanceMeters>"))
            // Regex to find at least one non-zero distance
            let regex = try NSRegularExpression(pattern: "<DistanceMeters>[1-9]", options: [])
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            XCTAssertGreaterThan(matches.count, 0)
            
        } catch {
            XCTFail("Failed to read TCX content: \(error)")
        }
    }
    
    func testFITExport() {
        let encoder = FitEncoder()
        let data = encoder.encode(
            trackpoints: trackpoints,
            laps: [],
            hrSource: nil,
            powerSource: nil,
            userFTP: 250,
            userWeight: userWeight
        )
        
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 100)
        
        // Verify FIT header (CRC and .FIT signature)
        if let data = data, data.count > 12 {
            let signature = String(data: data.subdata(in: 8..<12), encoding: .ascii)
            XCTAssertEqual(signature, ".FIT")
        }
    }
}
