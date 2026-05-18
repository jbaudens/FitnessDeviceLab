import Testing
import Foundation
@testable import FitnessDeviceLab

struct HRVEngineTests {
    
    @Test func testDFAAlpha1WithWhiteNoise() {
        // White noise should have Alpha 1 of approx 0.5
        var beats: [Beat] = []
        let now = Date()
        var seed = 12345
        func seededRandom() -> Double {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff
            return Double(seed) / Double(0x7fffffff)
        }
        
        for i in 0..<400 {
            let rr = 0.9 + (seededRandom() * 0.2) // 0.9 to 1.1
            beats.append(Beat(time: now.addingTimeInterval(Double(i)), rr: rr))
        }
        
        let metrics = HRVEngine.calculateMetrics(beats: beats)
        if let alpha = metrics.dfaAlpha1 {
            #expect(alpha > 0.35 && alpha < 0.65, "White noise expected 0.5, got \(alpha)")
        } else {
            Issue.record("Alpha 1 was not calculated")
        }
    }
    
    @Test func testDFAAlpha1WithBrownianMotion() {
        // Random walk should have Alpha 1 of approx 1.5
        var beats: [Beat] = []
        let now = Date()
        var seed = 54321
        func seededRandom() -> Double {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff
            return Double(seed) / Double(0x7fffffff)
        }
        
        var currentRR = 1.0
        for i in 0..<400 {
            currentRR += (seededRandom() - 0.5) * 0.02
            beats.append(Beat(time: now.addingTimeInterval(Double(i)), rr: currentRR))
        }
        
        let metrics = HRVEngine.calculateMetrics(beats: beats)
        if let alpha = metrics.dfaAlpha1 {
            #expect(alpha > 1.3 && alpha < 1.7, "Brownian motion expected 1.5, got \(alpha)")
        } else {
            Issue.record("Alpha 1 was not calculated")
        }
    }
}
