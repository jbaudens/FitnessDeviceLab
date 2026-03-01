import SwiftUI
import Charts
import Combine

struct HRComparisonView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    @State private var selectedDeviceAId: UUID?
    @State private var selectedDeviceBId: UUID?
    
    var hrDevices: [DiscoveredPeripheral] {
        bluetoothManager.peripherals.filter { $0.capabilities.contains(.heartRate) && $0.isConnected }
    }
    
    var deviceA: DiscoveredPeripheral? {
        hrDevices.first { $0.id == selectedDeviceAId }
    }
    
    var deviceB: DiscoveredPeripheral? {
        hrDevices.first { $0.id == selectedDeviceBId }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if hrDevices.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Connected HR Monitors")
                            .font(.headline)
                        Text("Connect to heart rate monitors from the Devices tab to compare them here.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    VStack {
                        // Selectors
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Device A (Red)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Picker("Device A", selection: $selectedDeviceAId) {
                                    Text("None").tag(UUID?.none)
                                    ForEach(hrDevices) { device in
                                        Text(device.name).tag(UUID?.some(device.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.red)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Device B (Blue)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Picker("Device B", selection: $selectedDeviceBId) {
                                    Text("None").tag(UUID?.none)
                                    ForEach(hrDevices) { device in
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
                                HRComparisonDashboard(deviceA: devA, deviceB: devB)
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
            .navigationTitle("HR Comparison")
            .onAppear {
                if hrDevices.count >= 1 && selectedDeviceAId == nil {
                    selectedDeviceAId = hrDevices[0].id
                }
                if hrDevices.count >= 2 && selectedDeviceBId == nil {
                    selectedDeviceBId = hrDevices[1].id
                }
            }
        }
    }
}

struct HRComparisonDashboard: View {
    @ObservedObject var deviceA: DiscoveredPeripheral
    @ObservedObject var deviceB: DiscoveredPeripheral
    
    @State private var diffHistories: [DataFieldType: [TimeSeriesDataPoint]] = [:]
    @State private var selectedGraphField: DataFieldType = .currentHR
    
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
    
    let graphableFields: [DataFieldType] = [.currentHR, .dfaAlpha1, .avgHR]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Values Summary
                HStack {
                    VStack {
                        Text(deviceA.name).font(.caption).foregroundColor(.red).lineLimit(1)
                        Text(deviceA.heartRate != nil ? "\(deviceA.heartRate!)" : "--")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.red)
                        Text("BPM").font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack {
                        Text("Difference")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let hrA = deviceA.heartRate, let hrB = deviceB.heartRate {
                            let diff = hrA - hrB
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
                        Text(deviceB.heartRate != nil ? "\(deviceB.heartRate!)" : "--")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.blue)
                        Text("BPM").font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                // Derived Data Fields
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Device A Derived").font(.caption).foregroundColor(.secondary)
                        DataFieldGrid(hrPeripheral: deviceA, fields: [.avgHR, .maxHR], columnsCount: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Device B Derived").font(.caption).foregroundColor(.secondary)
                        DataFieldGrid(hrPeripheral: deviceB, fields: [.avgHR, .maxHR], columnsCount: 1)
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
                        if let avg = avgDiff {
                            Text(String(format: "Avg Diff: %+.2f", avg))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if currentDiffHistory.isEmpty {
                        Text("Waiting for data...")
                            .foregroundColor(.secondary)
                            .frame(height: 150)
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
                                .interpolationMethod(selectedGraphField == .dfaAlpha1 ? .stepCenter : .catmullRom)
                                
                                AreaMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Diff", point.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(colors: [.purple.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                                )
                            }
                            .foregroundStyle(.purple)
                        }
                        .frame(height: 150)
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
