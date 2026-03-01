import SwiftUI

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
    case aapAcclimated = "AAP (Acclimated)"
    case aapNonAcclimated = "AAP (Non-Accl)"
    case powerBalance = "L/R Balance"
    
    case cadence = "Cadence"
    case avgCadence = "Avg Cadence"
    case maxCadence = "Max Cadence"
    
    var id: String { rawValue }
    
    var isHR: Bool {
        switch self {
        case .currentHR, .avgHR, .maxHR, .dfaAlpha1, .avnn, .sdnn, .rmssd, .pnn50: return true
        default: return false
        }
    }
    
    func value(for peripheral: DiscoveredPeripheral) -> Double? {
        switch self {
        case .currentHR: return peripheral.heartRate.map { Double($0) }
        case .avgHR: return peripheral.metrics.avgHeartRate
        case .maxHR: return peripheral.metrics.maxHeartRate.map { Double($0) }
        case .dfaAlpha1: return peripheral.metrics.dfaAlpha1
        case .avnn: return peripheral.metrics.avnn
        case .sdnn: return peripheral.metrics.sdnn
        case .rmssd: return peripheral.metrics.rmssd
        case .pnn50: return peripheral.metrics.pnn50
        
        case .currentPower: return peripheral.cyclingPower.map { Double($0) }
        case .power3s: return peripheral.metrics.power3s.map { Double($0) }
        case .power10s: return peripheral.metrics.power10s.map { Double($0) }
        case .power30s: return peripheral.metrics.power30s.map { Double($0) }
        case .avgPower: return peripheral.metrics.avgPower
        case .maxPower: return peripheral.metrics.maxPower.map { Double($0) }
        case .normalizedPower: return peripheral.metrics.normalizedPower
        case .intensityFactor: return peripheral.metrics.intensityFactor
        case .tss: return peripheral.metrics.tss
        case .aapAcclimated: return peripheral.metrics.altitudeAdjustedPowerAcclimated.map { Double($0) }
        case .aapNonAcclimated: return peripheral.metrics.altitudeAdjustedPowerNonAcclimated.map { Double($0) }
        case .powerBalance: return peripheral.powerBalance
        
        case .cadence: return peripheral.cadence.map { Double($0) }
        case .avgCadence: return peripheral.metrics.avgCadence
        case .maxCadence: return peripheral.metrics.maxCadence.map { Double($0) }
        }
    }
}

struct DataFieldGrid: View {
    var hrPeripheral: DiscoveredPeripheral?
    var powerPeripheral: DiscoveredPeripheral?
    let fields: [DataFieldType]
    var columnsCount: Int = 2
    
    var body: some View {
        let cols = Array(repeating: GridItem(.flexible()), count: columnsCount)
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(0..<fields.count, id: \.self) { index in
                DataFieldTileHelper(type: fields[index], hrPeripheral: hrPeripheral, powerPeripheral: powerPeripheral)
            }
        }
    }
}

struct DataFieldTileHelper: View {
    let type: DataFieldType
    var hrPeripheral: DiscoveredPeripheral?
    var powerPeripheral: DiscoveredPeripheral?

    var body: some View {
        if type.isHR {
            if let hr = hrPeripheral {
                DataFieldTile(type: type, peripheral: hr)
            } else {
                EmptyTile(type: type)
            }
        } else {
            if let power = powerPeripheral {
                DataFieldTile(type: type, peripheral: power)
            } else {
                EmptyTile(type: type)
            }
        }
    }
}

struct EmptyTile: View {
    let type: DataFieldType
    
    var body: some View {
        VStack(spacing: 4) {
            Text(type.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text("--")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    var unit: String {
        switch type {
        case .currentHR, .avgHR, .maxHR: return "BPM"
        case .dfaAlpha1: return "INDEX"
        case .avnn, .sdnn, .rmssd: return "ms"
        case .pnn50: return "%"
        case .currentPower, .power3s, .power10s, .power30s, .avgPower, .maxPower, .normalizedPower, .aapAcclimated, .aapNonAcclimated: return "W"
        case .intensityFactor: return "IF"
        case .tss: return "TSS"
        case .cadence, .avgCadence, .maxCadence: return "RPM"
        case .powerBalance: return "% L"
        }
    }
    
    var color: Color {
        switch type {
        case .currentHR, .avgHR, .maxHR: return .red
        case .dfaAlpha1, .avnn, .sdnn, .rmssd, .pnn50: return .purple
        case .currentPower, .power3s, .power10s, .power30s, .avgPower, .maxPower, .normalizedPower, .aapAcclimated, .aapNonAcclimated: return .yellow
        case .intensityFactor, .tss: return .orange
        case .cadence, .avgCadence, .maxCadence: return .blue
        case .powerBalance: return .orange
        }
    }
}

struct DataFieldTile: View {
    let type: DataFieldType
    @ObservedObject var peripheral: DiscoveredPeripheral
    
    var body: some View {
        VStack(spacing: 4) {
            Text(type.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(valueText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    var valueText: String {
        guard let val = type.value(for: peripheral) else { return "--" }
        
        switch type {
        case .dfaAlpha1, .intensityFactor: return String(format: "%.2f", val)
        case .tss: return String(format: "%.1f", val)
        default: return String(format: "%.0f", val)
        }
    }
    
    var unit: String {
        switch type {
        case .currentHR, .avgHR, .maxHR: return "BPM"
        case .dfaAlpha1: return "INDEX"
        case .avnn, .sdnn, .rmssd: return "ms"
        case .pnn50: return "%"
        case .currentPower, .power3s, .power10s, .power30s, .avgPower, .maxPower, .normalizedPower, .aapAcclimated, .aapNonAcclimated: return "W"
        case .intensityFactor: return "IF"
        case .tss: return "TSS"
        case .cadence, .avgCadence, .maxCadence: return "RPM"
        case .powerBalance: return "% L"
        }
    }
    
    var color: Color {
        switch type {
        case .currentHR, .avgHR, .maxHR: return .red
        case .dfaAlpha1, .avnn, .sdnn, .rmssd, .pnn50: return .purple
        case .currentPower, .power3s, .power10s, .power30s, .avgPower, .maxPower, .normalizedPower, .aapAcclimated, .aapNonAcclimated: return .yellow
        case .intensityFactor, .tss: return .orange
        case .cadence, .avgCadence, .maxCadence: return .blue
        case .powerBalance: return .orange
        }
    }
}
