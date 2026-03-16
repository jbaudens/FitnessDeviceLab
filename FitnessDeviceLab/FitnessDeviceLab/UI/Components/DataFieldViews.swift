import SwiftUI
import Charts
import Combine

public enum DataFieldType: String, CaseIterable, Identifiable, Codable {
    // Heart Rate
    case currentHR = "Heart Rate"
    case avgHR = "Avg HR"
    case maxHR = "Max HR"
    case minHR = "Min HR"
    
    // HRV
    case dfaAlpha1 = "DFA-a1"
    case avnn = "AVNN"
    case sdnn = "SDNN"
    case rmssd = "rMSSD"
    case pnn50 = "pNN50"
    
    // Standard Power
    case currentPower = "Power"
    case power3s = "3s Power"
    case power10s = "10s Power"
    case power30s = "30s Power"
    case avgPower = "Avg Power"
    case maxPower = "Max Power"
    case minPower = "Min Power"
    case normalizedPower = "NP®"
    case intensityFactor = "IF®"
    case tss = "TSS®"
    case wattsPerKg = "Watts/kg"
    case localFTP = "Local FTP"
    case powerBalance = "L/R Bal"
    
    // Sea Level Equivalent
    case slPower = "Sea Level Power"
    case slPower3s = "Sea Level 3s Pwr"
    case slPower10s = "Sea Level 10s Pwr"
    case slPower30s = "Sea Level 30s Pwr"
    case slAvgPower = "Sea Level Avg Pwr"
    case slMaxPower = "Sea Level Max Pwr"
    case slMinPower = "Sea Level Min Pwr"
    case slNP = "Sea Level NP®"
    case slIF = "Sea Level IF®"
    case slTSS = "Sea Level TSS®"
    case slWkg = "Sea Level W/kg"
    case slFTP = "Sea Level FTP"
    
    // Home Equivalent
    case homePower = "Home Power"
    case homePower3s = "Home 3s Pwr"
    case homePower10s = "Home 10s Pwr"
    case homePower30s = "Home 30s Pwr"
    case homeAvgPower = "Home Avg Pwr"
    case homeMaxPower = "Home Max Pwr"
    case homeMinPower = "Home Min Pwr"
    case homeNP = "Home NP®"
    case homeIF = "Home IF®"
    case homeTSS = "Home TSS®"
    case homeWkg = "Home W/kg"
    case homeFTP = "Home FTP"
    
    // Cadence
    case cadence = "Cadence"
    case avgCadence = "Avg Cad"
    case maxCadence = "Max Cad"
    case minCadence = "Min Cad"
    
    // Motion & Environment
    case speed = "Speed"
    case avgSpeed = "Avg Speed"
    case distance = "Distance"
    case altitude = "Altitude"
    
    // Lap Metrics
    case lapAvgPower = "Lap Avg Pwr"
    case lapMaxPower = "Lap Max Pwr"
    case lapMinPower = "Lap Min Pwr"
    case lapNP = "Lap NP®"
    case lapIF = "Lap IF®"
    case lapTSS = "Lap TSS®"
    case lapAvgHR = "Lap Avg HR"
    case lapMaxHR = "Lap Max HR"
    case lapMinHR = "Lap Min HR"
    case lapAvgCadence = "Lap Avg Cad"
    case lapMaxCadence = "Lap Max Cad"
    case lapMinCadence = "Lap Min Cad"
    case lapTime = "Lap Time"
    case lapSpeed = "Lap Speed"
    case lapAvgSpeed = "Lap Avg Speed"
    case lapMaxSpeed = "Lap Max Speed"
    case lapDistance = "Lap Dist"
    
    // Lap Sea Level
    case lapSlAvgPower = "Lap Sea Level Avg Pwr"
    case lapSlMaxPower = "Lap Sea Level Max Pwr"
    case lapSlMinPower = "Lap Sea Level Min Pwr"
    case lapSlNP = "Lap Sea Level NP®"
    case lapSlIF = "Lap Sea Level IF®"
    case lapSlTSS = "Lap Sea Level TSS®"
    case lapSlWkg = "Lap Sea Level W/kg"
    
    // Lap Home
    case lapHomeAvgPower = "Lap Home Avg Pwr"
    case lapHomeMaxPower = "Lap Home Max Pwr"
    case lapHomeMinPower = "Lap Home Min Pwr"
    case lapHomeNP = "Lap Home NP®"
    case lapHomeIF = "Lap Home IF®"
    case lapHomeTSS = "Lap Home TSS®"
    case lapHomeWkg = "Lap Home W/kg"
    
    public var id: String { rawValue }
    
    var isHR: Bool {
        switch self {
        case .currentHR, .avgHR, .maxHR, .minHR, .lapAvgHR, .lapMaxHR, .lapMinHR: return true
        default: return false
        }
    }
    
    func value(for engine: DataFieldEngine, settings: SettingsProvider) -> Double? {
        let m = engine.calculatedMetrics
        let hrv = engine.hrvMetrics
        
        switch self {
        case .currentHR: return engine.currentHR.map { Double($0) }
        case .avgHR: return m.hr.avg
        case .maxHR: return m.hr.max.map { Double($0) }
        case .minHR: return m.hr.min.map { Double($0) }
        case .dfaAlpha1: return hrv.dfaAlpha1
        case .avnn: return hrv.avnn
        case .sdnn: return hrv.sdnn
        case .rmssd: return hrv.rmssd
        case .pnn50: return hrv.pnn50
        
        case .currentPower: return engine.liveStandard.instant.map { Double($0) }
        case .power3s: return engine.liveStandard.power3s.map { Double($0) }
        case .power10s: return engine.liveStandard.power10s.map { Double($0) }
        case .power30s: return engine.liveStandard.power30s.map { Double($0) }
        case .avgPower: return m.standard.avgPower
        case .maxPower: return m.standard.maxPower.map { Double($0) }
        case .minPower: return m.standard.minPower.map { Double($0) }
        case .normalizedPower: return m.standard.normalizedPower
        case .intensityFactor: return m.standard.intensityFactor
        case .tss: return m.standard.tss
        case .wattsPerKg: return engine.liveStandard.wattsPerKg
        case .localFTP: return engine.localFTP
        case .powerBalance: return engine.powerBalance
        
        case .slPower: return engine.liveSeaLevel.instant.map { Double($0) }
        case .slPower3s: return engine.liveSeaLevel.power3s.map { Double($0) }
        case .slPower10s: return engine.liveSeaLevel.power10s.map { Double($0) }
        case .slPower30s: return engine.liveSeaLevel.power30s.map { Double($0) }
        case .slAvgPower: return m.seaLevel.avgPower
        case .slMaxPower: return m.seaLevel.maxPower.map { Double($0) }
        case .slMinPower: return m.seaLevel.minPower.map { Double($0) }
        case .slNP: return m.seaLevel.normalizedPower
        case .slIF: return m.seaLevel.intensityFactor
        case .slTSS: return m.seaLevel.tss
        case .slWkg: return engine.liveSeaLevel.wattsPerKg
        case .slFTP: return engine.slFTP
        
        case .homePower: return engine.liveHome.instant.map { Double($0) }
        case .homePower3s: return engine.liveHome.power3s.map { Double($0) }
        case .homePower10s: return engine.liveHome.power10s.map { Double($0) }
        case .homePower30s: return engine.liveHome.power30s.map { Double($0) }
        case .homeAvgPower: return m.home.avgPower
        case .homeMaxPower: return m.home.maxPower.map { Double($0) }
        case .homeMinPower: return m.home.minPower.map { Double($0) }
        case .homeNP: return m.home.normalizedPower
        case .homeIF: return m.home.intensityFactor
        case .homeTSS: return m.home.tss
        case .homeWkg: return engine.liveHome.wattsPerKg
        case .homeFTP: return settings.userFTP
        
        case .cadence: return engine.currentCadence.map { Double($0) }
        case .avgCadence: return m.cadence.avg
        case .maxCadence: return m.cadence.max.map { Double($0) }
        case .minCadence: return m.cadence.min.map { Double($0) }
        
        case .altitude: return engine.currentAltitude
        case .speed: return engine.currentSpeed
        case .avgSpeed: return m.speed.avg
        case .distance: return m.speed.distance
        
        case .lapAvgPower: return engine.currentLapMetrics.standard.avgPower
        case .lapMaxPower: return engine.currentLapMetrics.standard.maxPower.map { Double($0) }
        case .lapMinPower: return engine.currentLapMetrics.standard.minPower.map { Double($0) }
        case .lapNP: return engine.currentLapMetrics.standard.normalizedPower
        case .lapIF: return engine.currentLapMetrics.standard.intensityFactor
        case .lapTSS: return engine.currentLapMetrics.standard.tss
        case .lapAvgHR: return engine.currentLapMetrics.hr.avg
        case .lapMaxHR: return engine.currentLapMetrics.hr.max.map { Double($0) }
        case .lapMinHR: return engine.currentLapMetrics.hr.min.map { Double($0) }
        case .lapAvgCadence: return engine.currentLapMetrics.cadence.avg
        case .lapMaxCadence: return engine.currentLapMetrics.cadence.max.map { Double($0) }
        case .lapMinCadence: return engine.currentLapMetrics.cadence.min.map { Double($0) }
        case .lapAvgSpeed, .lapSpeed: return engine.currentLapMetrics.speed.avg
        case .lapMaxSpeed: return engine.currentLapMetrics.speed.max
        case .lapDistance: return engine.currentLapMetrics.speed.distance
        case .lapTime:
            if let start = engine.lapStartTime {
                return Date().timeIntervalSince(start)
            }
            return 0
            
        case .lapSlAvgPower: return engine.currentLapMetrics.seaLevel.avgPower
        case .lapSlMaxPower: return engine.currentLapMetrics.seaLevel.maxPower.map { Double($0) }
        case .lapSlMinPower: return engine.currentLapMetrics.seaLevel.minPower.map { Double($0) }
        case .lapSlNP: return engine.currentLapMetrics.seaLevel.normalizedPower
        case .lapSlIF: return engine.currentLapMetrics.seaLevel.intensityFactor
        case .lapSlTSS: return engine.currentLapMetrics.seaLevel.tss
        case .lapSlWkg: return engine.currentLapMetrics.standard.avgPower.map { $0 / (engine.calculatedMetrics.standard.ftp ?? 1.0) } // Simplified fallback or nil
            
        case .lapHomeAvgPower: return engine.currentLapMetrics.home.avgPower
        case .lapHomeMaxPower: return engine.currentLapMetrics.home.maxPower.map { Double($0) }
        case .lapHomeMinPower: return engine.currentLapMetrics.home.minPower.map { Double($0) }
        case .lapHomeNP: return engine.currentLapMetrics.home.normalizedPower
        case .lapHomeIF: return engine.currentLapMetrics.home.intensityFactor
        case .lapHomeTSS: return engine.currentLapMetrics.home.tss
        case .lapHomeWkg: return nil
        }
    }
    
    var unit: String {
        switch self {
        case .currentHR, .avgHR, .maxHR, .minHR, .lapAvgHR, .lapMaxHR, .lapMinHR: return "bpm"
        case .dfaAlpha1: return "idx"
        case .avnn, .sdnn, .rmssd: return "ms"
        case .pnn50: return "%"
        case .currentPower, .power3s, .power10s, .power30s, .avgPower, .maxPower, .minPower, .normalizedPower, .localFTP, .slPower, .slPower3s, .slPower10s, .slPower30s, .slAvgPower, .slMaxPower, .slMinPower, .slNP, .slFTP, .homePower, .homePower3s, .homePower10s, .homePower30s, .homeAvgPower, .homeMaxPower, .homeMinPower, .homeNP, .homeFTP, .lapAvgPower, .lapMaxPower, .lapMinPower, .lapNP, .lapSlAvgPower, .lapSlMaxPower, .lapSlMinPower, .lapSlNP, .lapHomeAvgPower, .lapHomeMaxPower, .lapHomeMinPower, .lapHomeNP: return "W"
        case .intensityFactor, .slIF, .homeIF, .lapIF, .lapSlIF, .lapHomeIF: return "IF"
        case .tss, .slTSS, .homeTSS, .lapTSS, .lapSlTSS, .lapHomeTSS: return "TSS"
        case .cadence, .avgCadence, .maxCadence, .minCadence, .lapAvgCadence, .lapMaxCadence, .lapMinCadence: return "rpm"
        case .powerBalance: return "%L"
        case .altitude: return "m"
        case .speed, .avgSpeed, .lapSpeed, .lapAvgSpeed, .lapMaxSpeed: return "km/h"
        case .distance, .lapDistance: return "km"
        case .lapTime: return ""
        case .wattsPerKg, .slWkg, .homeWkg, .lapSlWkg, .lapHomeWkg: return "W/kg"
        }
    }
    
    var color: Color {
        switch self {
        case .currentHR, .avgHR, .maxHR, .minHR, .lapAvgHR, .lapMaxHR, .lapMinHR: return .red
        case .dfaAlpha1, .avnn, .sdnn, .rmssd, .pnn50: return .purple
        case .intensityFactor, .tss, .slIF, .slTSS, .homeIF, .homeTSS, .lapNP, .lapIF, .lapTSS, .lapSlNP, .lapSlIF, .lapSlTSS, .lapHomeNP, .lapHomeIF, .lapHomeTSS: return .orange
        case .cadence, .avgCadence, .maxCadence, .minCadence, .lapAvgCadence, .lapMaxCadence, .lapMinCadence: return .blue
        case .speed, .avgSpeed, .lapSpeed, .lapAvgSpeed, .lapMaxSpeed, .distance, .lapDistance: return .green
        case .powerBalance: return .orange
        case .altitude: return .green
        case .lapTime: return .secondary
        default: return .yellow
        }
    }
    
    func format(_ value: Double) -> String {
        switch self {
        case .dfaAlpha1, .intensityFactor, .wattsPerKg, .slWkg, .homeWkg, .slIF, .homeIF, .lapIF, .lapSlIF, .lapHomeIF, .lapSlWkg, .lapHomeWkg: return String(format: "%.2f", value)
        case .tss, .slTSS, .homeTSS, .lapTSS, .lapSlTSS, .lapHomeTSS: return String(format: "%.1f", value)
        case .speed, .avgSpeed, .lapSpeed, .lapAvgSpeed, .lapMaxSpeed: return String(format: "%.1f", value * 3.6)
        case .distance, .lapDistance: return String(format: "%.2f", value / 1000.0)
        case .lapTime:
            let m = Int(value) / 60
            let s = Int(value) % 60
            return String(format: "%d:%02d", m, s)
        default: return String(format: "%.0f", value)
        }
    }
}

// MARK: - Components

struct DataFieldGrid: View {
    var engine: DataFieldEngine
    let fields: [DataFieldType]
    let settings: SettingsProvider
    
    var body: some View {
        let columnsCount = 6
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: columnsCount)
        
        LazyVGrid(columns: cols, spacing: 8) {
            ForEach(fields) { field in
                DataFieldTile(type: field, engine: engine, settings: settings)
            }
        }
    }
}

struct DataFieldTile: View {
    let type: DataFieldType
    var engine: DataFieldEngine
    let settings: SettingsProvider
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                Text(type.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .lineLimit(1)
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(valueText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(type.color)
                        .lineLimit(1)
                    
                    Text(type.unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(type.color.opacity(0.08))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(type.color.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    var valueText: String {
        guard let val = type.value(for: engine, settings: settings) else { return "--" }
        return type.format(val)
    }
}
