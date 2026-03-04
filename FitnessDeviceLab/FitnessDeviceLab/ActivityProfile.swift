import SwiftUI

nonisolated struct ActivityProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var pages: [DataPage]
    
    static let defaultProfile = ActivityProfile(
        name: "Cycling",
        pages: [
            // Page 1: General
            DataPage(fields: [
                .currentPower, .currentHR,
                .power3s, .cadence,
                .aapAcclimated, .aapNonAcclimated,
                .altitude
            ]),
            
            // Page 2: Power Focus
            DataPage(fields: [
                .currentPower, .power3s,
                .power10s, .power30s,
                .avgPower, .maxPower,
                .normalizedPower, .intensityFactor,
                .tss, .powerBalance
            ]),
            
            // Page 3: HR & HRV Focus
            DataPage(fields: [
                .currentHR, .avgHR,
                .maxHR, .dfaAlpha1,
                .rmssd, .sdnn,
                .avnn, .pnn50
            ])
        ]
    )
}

nonisolated struct DataPage: Identifiable, Codable, Hashable {
    var id = UUID()
    var fields: [DataFieldType]
}
