import SwiftUI
import Charts
import Combine

enum DataFieldType: String, CaseIterable, Identifiable, Codable {
    // Heart Rate
    case currentHR = "Heart Rate"
    case avgHR = "Avg HR"
    case maxHR = "Max HR"
    
    // HRV
    case dfaAlpha1 = "DFA-a1"
    case avnn = "AVNN"
    case sdnn = "SDNN"
    case rmssd = "rMSSD"
    case pnn50 = "pNN50"
    
    // Standard Power (Local Altitude)
    case currentPower = "Power"
    case power3s = "3s Power"
    case power10s = "10s Power"
    case power30s = "30s Power"
    case avgPower = "Avg Power"
    case maxPower = "Max Power"
    case normalizedPower = "NP®"
    case intensityFactor = "IF®"
    case tss = "TSS®"
    case wattsPerKg = "Watts/kg"
    case localFTP = "Local FTP"
    case powerBalance = "L/R Bal"
    
    // Sea Level Equivalent (0m)
    case slPower = "SL Power"
    case slPower3s = "SL 3s Pwr"
    case slPower10s = "SL 10s Pwr"
    case slPower30s = "SL 30s Pwr"
    case slAvgPower = "SL Avg Pwr"
    case slMaxPower = "SL Max Pwr"
    case slNP = "SL NP®"
    case slIF = "SL IF®"
    case slTSS = "SL TSS®"
    case slWkg = "SL W/kg"
    case slFTP = "SL FTP"
    
    // Home Equivalent (ftpAltitude)
    case homePower = "Home Power"
    case homePower3s = "Home 3s Pwr"
    case homePower10s = "Home 10s Pwr"
    case homePower30s = "Home 30s Pwr"
    case homeAvgPower = "Home Avg Pwr"
    case homeMaxPower = "Home Max Pwr"
    case homeNP = "Home NP®"
    case homeIF = "Home IF®"
    case homeTSS = "Home TSS®"
    case homeWkg = "Home W/kg"
    case homeFTP = "Home FTP"
    
    // Cadence
    case cadence = "Cadence"
    case avgCadence = "Avg Cad"
    case maxCadence = "Max Cad"
    
    // Environment
    case altitude = "Altitude"
    
    var id: String { rawValue }
    
    var isHR: Bool {
        switch self {
        case .currentHR, .avgHR, .maxHR, .dfaAlpha1, .avnn, .sdnn, .rmssd, .pnn50: return true
        default: return false
        }
    }
    
    func value(for recorder: SessionRecorder) -> Double? {
        let m = recorder.calculatedMetrics
        let hrv = recorder.hrvMetrics
        
        switch self {
        case .currentHR: return recorder.hrDevice?.heartRate.map { Double($0) }
        case .avgHR: return m.avgHeartRate
        case .maxHR: return m.maxHeartRate.map { Double($0) }
        case .dfaAlpha1: return hrv.dfaAlpha1
        case .avnn: return hrv.avnn
        case .sdnn: return hrv.sdnn
        case .rmssd: return hrv.rmssd
        case .pnn50: return hrv.pnn50
        
        case .currentPower: return m.standard.instantPower.map { Double($0) }
        case .power3s: return m.standard.power3s.map { Double($0) }
        case .power10s: return m.standard.power10s.map { Double($0) }
        case .power30s: return m.standard.power30s.map { Double($0) }
        case .avgPower: return m.standard.avgPower
        case .maxPower: return m.standard.maxPower.map { Double($0) }
        case .normalizedPower: return m.standard.normalizedPower
        case .intensityFactor: return m.standard.intensityFactor
        case .tss: return m.standard.tss
        case .wattsPerKg: return m.standard.wattsPerKg
        case .localFTP: return m.standard.ftp
        case .powerBalance: return recorder.powerDevice?.powerBalance
        
        case .slPower: return m.seaLevel.instantPower.map { Double($0) }
        case .slPower3s: return m.seaLevel.power3s.map { Double($0) }
        case .slPower10s: return m.seaLevel.power10s.map { Double($0) }
        case .slPower30s: return m.seaLevel.power30s.map { Double($0) }
        case .slAvgPower: return m.seaLevel.avgPower
        case .slMaxPower: return m.seaLevel.maxPower.map { Double($0) }
        case .slNP: return m.seaLevel.normalizedPower
        case .slIF: return m.seaLevel.intensityFactor
        case .slTSS: return m.seaLevel.tss
        case .slWkg: return m.seaLevel.wattsPerKg
        case .slFTP: return m.seaLevel.ftp
        
        case .homePower: return m.home.instantPower.map { Double($0) }
        case .homePower3s: return m.home.power3s.map { Double($0) }
        case .homePower10s: return m.home.power10s.map { Double($0) }
        case .homePower30s: return m.home.power30s.map { Double($0) }
        case .homeAvgPower: return m.home.avgPower
        case .homeMaxPower: return m.home.maxPower.map { Double($0) }
        case .homeNP: return m.home.normalizedPower
        case .homeIF: return m.home.intensityFactor
        case .homeTSS: return m.home.tss
        case .homeWkg: return m.home.wattsPerKg
        case .homeFTP: return m.home.ftp
        
        case .cadence: return recorder.powerDevice?.cadence.map { Double($0) }
        case .avgCadence: return m.avgCadence
        case .maxCadence: return m.maxCadence.map { Double($0) }
        
        case .altitude: return recorder.trackpoints.last?.altitude
        }
    }
    
    var unit: String {
        switch self {
        case .currentHR, .avgHR, .maxHR: return "bpm"
        case .dfaAlpha1: return "idx"
        case .avnn, .sdnn, .rmssd: return "ms"
        case .pnn50: return "%"
        case .currentPower, .power3s, .power10s, .power30s, .avgPower, .maxPower, .normalizedPower, .localFTP, .slPower, .slPower3s, .slPower10s, .slPower30s, .slAvgPower, .slMaxPower, .slNP, .slFTP, .homePower, .homePower3s, .homePower10s, .homePower30s, .homeAvgPower, .homeMaxPower, .homeNP, .homeFTP: return "W"
        case .intensityFactor, .slIF, .homeIF: return "IF"
        case .tss, .slTSS, .homeTSS: return "TSS"
        case .cadence, .avgCadence, .maxCadence: return "rpm"
        case .powerBalance: return "%L"
        case .altitude: return "m"
        case .wattsPerKg, .slWkg, .homeWkg: return "W/kg"
        }
    }
    
    var color: Color {
        switch self {
        case .currentHR, .avgHR, .maxHR: return .red
        case .dfaAlpha1, .avnn, .sdnn, .rmssd, .pnn50: return .purple
        case .intensityFactor, .tss, .slIF, .slTSS, .homeIF, .homeTSS: return .orange
        case .cadence, .avgCadence, .maxCadence: return .blue
        case .powerBalance: return .orange
        case .altitude: return .green
        default: return .yellow
        }
    }
}

struct DataFieldGrid: View {
    @ObservedObject var recorder: SessionRecorder
    let fields: [DataFieldType]
    
    var body: some View {
        let columnsCount = fields.count <= 2 ? 1 : (fields.count <= 4 ? 2 : 3)
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: columnsCount)
        
        LazyVGrid(columns: cols, spacing: 8) {
            ForEach(fields) { field in
                DataFieldTile(type: field, recorder: recorder)
            }
        }
    }
}

struct DataFieldTile: View {
    let type: DataFieldType
    @ObservedObject var recorder: SessionRecorder
    
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
        guard let val = type.value(for: recorder) else { return "--" }
        
        switch type {
        case .dfaAlpha1, .intensityFactor, .slIF, .homeIF, .wattsPerKg, .slWkg, .homeWkg: return String(format: "%.2f", val)
        case .tss, .slTSS, .homeTSS: return String(format: "%.1f", val)
        case .altitude: return String(format: "%.0f", val)
        default: return String(format: "%.0f", val)
        }
    }
}
