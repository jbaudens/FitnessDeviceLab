import SwiftUI

public enum GraphType: Codable, Identifiable, Hashable {
    case workout
    case dfaAlpha1
    case metric(DataFieldType)
    
    public var id: String {
        switch self {
        case .workout: return "workout"
        case .dfaAlpha1: return "dfaAlpha1"
        case .metric(let field): return "metric-\(field.rawValue)"
        }
    }
    
    public var title: String {
        switch self {
        case .workout: return "WORKOUT"
        case .dfaAlpha1: return "DFA a1"
        case .metric(let field): return field.rawValue.uppercased()
        }
    }
}

public struct ActivityProfile: Identifiable, Codable, Hashable {
    public var id = UUID()
    public var name: String
    public var iconName: String
    public var colorName: String
    public var pages: [DataPage]
    public var graphs: [GraphType]
    
    public init(id: UUID = UUID(), name: String, iconName: String, colorName: String, pages: [DataPage], graphs: [GraphType]) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.pages = pages
        self.graphs = graphs
    }
    
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
                .power3s, .slPower, .slPower3s, .powerBalance,
                .dfaAlpha1, .speed, .cadence,
                //lap
                .lapAvgPower, .lapNP, .lapAvgHR, .lapAvgCadence,
                //overall
                .avgPower, .normalizedPower, .slAvgPower, .slNP, .distance
            ]),
        ],
        graphs: [.workout]
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
        ],
        graphs: [.workout, .dfaAlpha1]
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
