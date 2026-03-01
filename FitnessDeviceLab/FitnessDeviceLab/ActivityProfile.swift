import SwiftUI

struct ActivityProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var pages: [DataPage]
    
    static let defaultProfile = ActivityProfile(
        name: "Cycling",
        pages: [
            DataPage(fields: [.currentPower, .currentHR, .cadence, .power3s]),
            DataPage(fields: [.normalizedPower, .intensityFactor, .tss, .powerBalance]),
            DataPage(fields: [.avgPower, .maxPower, .avgHR, .maxHR]),
            DataPage(fields: [.aapAcclimated, .aapNonAcclimated, .dfaAlpha1])
        ]
    )
}

struct DataPage: Identifiable, Codable, Hashable {
    var id = UUID()
    var fields: [DataFieldType]
}
