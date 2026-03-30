import SwiftUI

public struct ActivityProfile: Identifiable, Codable, Hashable {
    public var id = UUID()
    public var name: String
    public var iconName: String
    public var colorName: String
    public var pages: [DataPage]
    
    public var color: Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .blue
        }
    }
    
    public static let defaultProfile = ActivityProfile(
        name: "Cycling",
        iconName: "bicycle",
        colorName: "blue",
        pages: [
            // Page 1: General
            DataPage(fields: [
                // instant
                .currentPower, .power3s, .slPower, .slPower3s, .powerBalance,
                .currentHR, .dfaAlpha1, .speed, .cadence,
                //lap
                .lapAvgPower, .lapNP, .lapAvgHR, .lapAvgCadence,
                //overall
                .avgPower, .normalizedPower, .slAvgPower, .slNP, .distance
            ]),
        ]
    )
    
    public static let dfaAnalysisProfile = ActivityProfile(
        name: "DFA Analysis",
        iconName: "waveform.path.ecg",
        colorName: "purple",
        pages: [
            DataPage(fields: [
                .dfaAlpha1, .currentHR, .currentPower, .power3s,
                .avgHR, .avgPower, .rmssd, .sdnn,
                .lapAvgHR, .lapAvgPower, .lapTime, .distance
            ])
        ]
    )
    
    public static let availableProfiles: [ActivityProfile] = [
        .defaultProfile,
        .dfaAnalysisProfile
    ]
    
    /*public static let defaultProfile = ActivityProfile(
        name: "Cycling",
        pages: [
            // Page 1: General
            DataPage(fields: [
                .currentPower, .power3s, .powerBalance, .currentHR, .cadence,
                .speed, .distance, .normalizedPower, .avgPower
            ]),
            
            // Page 2: Lap Metrics
            DataPage(fields: [
                .lapAvgPower, .lapNP, .lapAvgHR, .lapCadence,
                .lapSpeed, .lapDistance, .lapTime, .intensityFactor, .tss
            ]),
            
            // Page 3: Power Focus
            DataPage(fields: [
                .currentPower, .power3s,
                .power10s, .power30s,
                .avgPower, .maxPower,
                .normalizedPower, .intensityFactor,
                .tss, .wattsPerKg,
                .localFTP
            ]),
            
            // Page 4: Home Equivalents (Normalized to ftpAltitude)
            DataPage(fields: [
                .homePower, .homePower3s,
                .homePower10s, .homePower30s,
                .homeAvgPower, .homeMaxPower,
                .homeNP, .homeIF, 
                .homeTSS, .homeWkg, 
                .homeFTP
            ]),
            
            // Page 4: Sea Level Equivalents (Normalized to 0m)
            DataPage(fields: [
                .slPower, .slPower3s,
                .slPower10s, .slPower30s,
                .slAvgPower, .slMaxPower,
                .slNP, .slIF, 
                .slTSS, .slWkg, 
                .slFTP
            ]),
            
            // Page 5: HR & HRV Focus
            DataPage(fields: [
                .currentHR, .avgHR,
                .maxHR, .dfaAlpha1,
                .rmssd, .sdnn,
                .avnn, .pnn50
            ]),
        ]
    )*/
}

public struct DataPage: Identifiable, Codable, Hashable {
    public var id = UUID()
    public var fields: [DataFieldType]
    
    public init(fields: [DataFieldType]) {
        self.fields = fields
    }
}
