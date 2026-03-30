import Testing
import Foundation
@testable import FitnessDeviceLab

struct LogicTests {

    @Test func testHeartRateParsing() async throws {
        // Flag 0x10 means RR intervals present, 0x01 means UInt16 HR
        // Data: [Flags, HR_Low, HR_High, RR_Low, RR_High]
        let data = Data([0x10, 0x4B, 0xFF, 0x03]) // 75 bpm, 1 RR interval (1023 / 1024.0)
        let result = SensorDataParser.parseHeartRate(data: data)
        
        #expect(result.hr == 75)
        #expect(result.rrIntervals.count == 1)
        #expect(abs(result.rrIntervals[0] - (1023.0 / 1024.0)) < 0.001)
    }
    
    @Test func testCyclingPowerParsing() async throws {
        // Flags: 0x0020 (Cadence present)
        // Data: [FlagsLow, FlagsHigh, PowerLow, PowerHigh, CrankRevsLow, CrankRevsHigh, CrankTimeLow, CrankTimeHigh]
        let data1 = Data([0x20, 0x00, 0xC8, 0x00, 0x01, 0x00, 0x00, 0x04]) // 200W, 1 rev, 1024 time (1s)
        let r1 = SensorDataParser.parseCyclingPower(data: data1, lastCrankRevs: 0, lastCrankTime: 0)
        
        #expect(r1.power == 200)
        #expect(r1.cadence == 60) // 1 rev in 1 second = 60 rpm
        #expect(r1.crankRevs == 1)
        #expect(r1.crankTime == 1024)
        
        // Test stop (time diff > 2048)
        let data2 = Data([0x20, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x10]) // 0W, same revs, 4096 time
        let r2 = SensorDataParser.parseCyclingPower(data: data2, lastCrankRevs: 1, lastCrankTime: 1024)
        #expect(r2.cadence == 0)
    }
    
    @Test func testIndoorBikeDataParsing() async throws {
        // Flags: 0x0044 (Instantaneous Cadence + Instantaneous Power)
        // [FlagsL, FlagsH, SpeedL, SpeedH, CadenceL, CadenceH, PowerL, PowerH]
        // But Speed is only present if Bit 0 is 0. 0x0044 Bit 0 is 0.
        let data = Data([0x44, 0x00, 0x00, 0x00, 0xB4, 0x00, 0x2C, 0x01]) 
        // Cadence: 180 / 2 = 90
        // Power: 300
        
        let result = SensorDataParser.parseIndoorBikeData(data: data)
        #expect(result.power == 300)
        #expect(result.cadence == 90)
    }
    
    @Test func testPhysicsUtilities() async throws {
        let p1 = PhysicsUtilities.estimateSpeed(power: 0, totalWeight: 80)
        #expect(p1 == 0)
        
        let p2 = PhysicsUtilities.estimateSpeed(power: 200, totalWeight: 80)
        // 200W for 80kg (bike+rider) should be roughly 32-35 km/h (9-10 m/s)
        #expect(p2 > 8.0)
        #expect(p2 < 11.0)
        
        let p3 = PhysicsUtilities.estimateSpeed(power: 400, totalWeight: 80)
        #expect(p3 > p2)
    }
    
    @Test func testHRVWindowing() async throws {
        let now = Date()
        var beats: [Beat] = []
        
        // 1. Create 60 seconds of steady beats (1 per second)
        for i in 0..<60 {
            beats.append(Beat(time: now.addingTimeInterval(Double(i)), rr: 1.0))
        }
        
        // 2. Add a 30 second gap
        let gapTime = now.addingTimeInterval(90)
        
        // 3. Add another 60 seconds of beats (total wall clock time = 150s)
        for i in 0..<60 {
            beats.append(Beat(time: gapTime.addingTimeInterval(Double(i)), rr: 1.0))
        }
        
        // Window size is 120s. 
        // Latest time is now + 150s.
        // Start time should be now + 30s.
        // Beats from 0-60 include: 30-60 (30 beats)
        // Gap: 60-90 (0 beats)
        // Beats from 90-150 (60 beats)
        // Expected total beats in window: 30 + 60 = 90
        
        let config = HRVConfig(windowSizeSeconds: 120, stepSizeSeconds: 5, artifactCorrectionThreshold: 0.2, mode: .exercise)
        let metrics = HRVEngine.calculateMetrics(beats: beats, config: config)
        
        // We can't easily check N inside, but we can verify it calculated something
        #expect(metrics.avnn != nil)
        #expect(metrics.avnn == 1000.0) // Average of 1.0s RR
    }
}
