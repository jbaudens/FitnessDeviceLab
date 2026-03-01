import SwiftUI
import Charts
import Combine

struct PowerComparisonView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    @State private var selectedDeviceAId: UUID?
    @State private var selectedDeviceBId: UUID?
    
    var powerDevices: [DiscoveredPeripheral] {
        bluetoothManager.peripherals.filter { 
            ($0.capabilities.contains(.cyclingPower) || $0.capabilities.contains(.fitnessMachine)) && $0.isConnected 
        }
    }
    
    var deviceA: DiscoveredPeripheral? {
        powerDevices.first { $0.id == selectedDeviceAId }
    }
    
    var deviceB: DiscoveredPeripheral? {
        powerDevices.first { $0.id == selectedDeviceBId }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if powerDevices.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bolt.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Connected Power Sources")
                            .font(.headline)
                        Text("Connect to power meters or smart trainers from the Devices tab to compare them here.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    VStack {
                        // Selectors
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Device A (Yellow)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Picker("Device A", selection: $selectedDeviceAId) {
                                    Text("None").tag(UUID?.none)
                                    ForEach(powerDevices) { device in
                                        Text(device.name).tag(UUID?.some(device.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.yellow)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Device B (Blue)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Picker("Device B", selection: $selectedDeviceBId) {
                                    Text("None").tag(UUID?.none)
                                    ForEach(powerDevices) { device in
                                        Text(device.name).tag(UUID?.some(device.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.blue)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Dashboard
                        if let devA = deviceA, let devB = deviceB {
                            if devA.id == devB.id {
                                Spacer()
                                Text("Please select two different devices.")
                                    .foregroundColor(.secondary)
                                Spacer()
                            } else {
                                PowerComparisonDashboard(deviceA: devA, deviceB: devB)
                            }
                        } else {
                            Spacer()
                            Text("Select two devices to start comparison.")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Power Comparison")
            .onAppear {
                if powerDevices.count >= 1 && selectedDeviceAId == nil {
                    selectedDeviceAId = powerDevices[0].id
                }
                if powerDevices.count >= 2 && selectedDeviceBId == nil {
                    selectedDeviceBId = powerDevices[1].id
                }
            }
        }
    }
}

struct PowerComparisonDashboard: View {
    @ObservedObject var deviceA: DiscoveredPeripheral
    @ObservedObject var deviceB: DiscoveredPeripheral
    
    @State private var diffHistories: [DataFieldType: [TimeSeriesDataPoint]] = [:]
    @State private var selectedGraphField: DataFieldType = .currentPower
    
    // Timer fires every second to sample both devices at the exact same time
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var currentDiffHistory: [TimeSeriesDataPoint] {
        diffHistories[selectedGraphField] ?? []
    }
    
    var avgDiff: Double? {
        let history = currentDiffHistory
        guard !history.isEmpty else { return nil }
        return history.map { $0.value }.reduce(0, +) / Double(history.count)
    }
    
    var stdDeviation: Double? {
        guard let avg = avgDiff, !currentDiffHistory.isEmpty else { return nil }
        let variance = currentDiffHistory.map { pow($0.value - avg, 2) }.reduce(0, +) / Double(currentDiffHistory.count)
        return sqrt(variance)
    }
    
    let graphableFields: [DataFieldType] = [.currentPower, .normalizedPower, .avgPower, .cadence, .powerBalance]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Values Summary
                HStack {
                    VStack {
                        Text(deviceA.name).font(.caption).foregroundColor(.yellow).lineLimit(1)
                        Text(deviceA.cyclingPower != nil ? "\(deviceA.cyclingPower!)" : "--")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("Watts").font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack {
                        Text("Difference")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let pwrA = deviceA.cyclingPower, let pwrB = deviceB.cyclingPower {
                            let diff = pwrA - pwrB
                            Text("\(abs(diff))")
                                .font(.system(size: 28, weight: .bold))
                            Text(diff == 0 ? "Matched" : (diff > 0 ? "A is higher" : "B is higher"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("--").font(.system(size: 28, weight: .bold))
                        }
                    }
                    Spacer()
                    VStack {
                        Text(deviceB.name).font(.caption).foregroundColor(.blue).lineLimit(1)
                        Text(deviceB.cyclingPower != nil ? "\(deviceB.cyclingPower!)" : "--")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Watts").font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                // Derived Data Fields
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Device A Derived").font(.caption).foregroundColor(.secondary)
                        DataFieldGrid(powerPeripheral: deviceA, fields: [.normalizedPower, .intensityFactor, .tss, .aapAcclimated], columnsCount: 2)
                    }
                    VStack(alignment: .leading) {
                        Text("Device B Derived").font(.caption).foregroundColor(.secondary)
                        DataFieldGrid(powerPeripheral: deviceB, fields: [.normalizedPower, .intensityFactor, .tss, .aapAcclimated], columnsCount: 2)
                    }
                }
                
                // Diff Chart
                VStack(alignment: .leading) {
                    HStack {
                        Picker("Graph Metric", selection: $selectedGraphField) {
                            ForEach(graphableFields) { field in
                                Text(field.rawValue).tag(field)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Spacer()
                        VStack(alignment: .trailing) {
                            if let avg = avgDiff {
                                Text(String(format: "Avg Diff: %+.1f", avg))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let dev = stdDeviation {
                                Text(String(format: "Std Dev: %.1f", dev))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if currentDiffHistory.isEmpty {
                        Text("Waiting for data...")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    } else {
                        Chart {
                            RuleMark(y: .value("Zero", 0))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(.gray)
                                
                            ForEach(currentDiffHistory) { point in
                                LineMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Diff", point.value)
                                )
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Diff", point.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(colors: [.green.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                                )
                            }
                            .foregroundStyle(.green)
                        }
                        .frame(height: 200)
                        .chartXAxis(.hidden)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .onReceive(timer) { _ in
            for field in graphableFields {
                if let valA = field.value(for: deviceA), let valB = field.value(for: deviceB) {
                    let diff = valA - valB
                    var history = diffHistories[field] ?? []
                    history.append(TimeSeriesDataPoint(value: diff))
                    if history.count > 120 { history.removeFirst() }
                    diffHistories[field] = history
                }
            }
        }
    }
}
