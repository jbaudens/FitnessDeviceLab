import SwiftUI
import Charts
import Combine

enum DataFieldType: String, CaseIterable, Identifiable, Codable {
    case currentHR = "Heart Rate"
    case avgHR = "Avg HR"
    case maxHR = "Max HR"
    case dfaAlpha1 = "DFA-a1"
    case avnn = "AVNN"
    case sdnn = "SDNN"
    case rmssd = "rMSSD"
    case pnn50 = "pNN50"
    
    case currentPower = "Power"
    case power3s = "3s Power"
    case power10s = "10s Power"
    case power30s = "30s Power"
    case avgPower = "Avg Power"
    case maxPower = "Max Power"
    case normalizedPower = "NP®"
    case intensityFactor = "IF®"
    case tss = "TSS®"
    case aapAcclimated = "AAP (Acc)"
    case aapNonAcclimated = "AAP (Non)"
    case powerBalance = "L/R Bal"
    
    case cadence = "Cadence"
    case avgCadence = "Avg Cad"
    case maxCadence = "Max Cad"
    
    case altitude = "Altitude"
    
    var id: String { rawValue }
    
    var isHR: Bool {
        switch self {
        case .currentHR, .avgHR, .maxHR, .dfaAlpha1, .avnn, .sdnn, .rmssd, .pnn50: return true
        default: return false
        }
    }
    
    func value(for recorder: SessionRecorder) -> Double? {
        let metrics = recorder.calculatedMetrics
        let hrv = recorder.hrvMetrics
        
        switch self {
        case .currentHR: return recorder.hrDevice?.heartRate.map { Double($0) }
        case .avgHR: return metrics.avgHeartRate
        case .maxHR: return metrics.maxHeartRate.map { Double($0) }
        case .dfaAlpha1: return hrv.dfaAlpha1
        case .avnn: return hrv.avnn
        case .sdnn: return hrv.sdnn
        case .rmssd: return hrv.rmssd
        case .pnn50: return hrv.pnn50
        
        case .currentPower: return recorder.powerDevice?.cyclingPower.map { Double($0) }
        case .power3s: return metrics.power3s.map { Double($0) }
        case .power10s: return metrics.power10s.map { Double($0) }
        case .power30s: return metrics.power30s.map { Double($0) }
        case .avgPower: return metrics.avgPower
        case .maxPower: return metrics.maxPower.map { Double($0) }
        case .normalizedPower: return metrics.normalizedPower
        case .intensityFactor: return metrics.intensityFactor
        case .tss: return metrics.tss
        case .aapAcclimated: return metrics.altitudeAdjustedPowerAcclimated.map { Double($0) }
        case .aapNonAcclimated: return metrics.altitudeAdjustedPowerNonAcclimated.map { Double($0) }
        case .powerBalance: return recorder.powerDevice?.powerBalance
        
        case .cadence: return recorder.powerDevice?.cadence.map { Double($0) }
        case .avgCadence: return metrics.avgCadence
        case .maxCadence: return metrics.maxCadence.map { Double($0) }
        
        case .altitude: return recorder.trackpoints.last?.altitude
        }
    }
    
    var unit: String {
        switch self {
        case .currentHR, .avgHR, .maxHR: return "bpm"
        case .dfaAlpha1: return "idx"
        case .avnn, .sdnn, .rmssd: return "ms"
        case .pnn50: return "%"
        case .currentPower, .power3s, .power10s, .power30s, .avgPower, .maxPower, .normalizedPower, .aapAcclimated, .aapNonAcclimated: return "W"
        case .intensityFactor: return "IF"
        case .tss: return "TSS"
        case .cadence, .avgCadence, .maxCadence: return "rpm"
        case .powerBalance: return "%L"
        case .altitude: return "m"
        }
    }
    
    var color: Color {
        switch self {
        case .currentHR, .avgHR, .maxHR: return .red
        case .dfaAlpha1, .avnn, .sdnn, .rmssd, .pnn50: return .purple
        case .currentPower, .power3s, .power10s, .power30s, .avgPower, .maxPower, .normalizedPower, .aapAcclimated, .aapNonAcclimated: return .yellow
        case .intensityFactor, .tss: return .orange
        case .cadence, .avgCadence, .maxCadence: return .blue
        case .powerBalance: return .orange
        case .altitude: return .green
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
        case .dfaAlpha1, .intensityFactor: return String(format: "%.2f", val)
        case .tss: return String(format: "%.1f", val)
        case .altitude: return String(format: "%.0f", val)
        default: return String(format: "%.0f", val)
        }
    }
}

// NOTE: MetricGraphView and ObservedChart removed.
// We now use WorkoutGraphView from WorkoutViews.swift for a unified target+actual display.
