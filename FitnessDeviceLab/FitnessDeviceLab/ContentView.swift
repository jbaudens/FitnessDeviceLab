import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var workoutManager: WorkoutSessionManager

    var body: some View {
        TabView {
            NavigationStack {
                VStack {
                    if bluetoothManager.isScanning {
                        ProgressView("Scanning for devices...")
                            .padding()
                    } else {
                        Button("Scan for Devices") {
                            bluetoothManager.startScanning()
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                    }

                    List {
                        let hrDevices = bluetoothManager.peripherals.filter { $0.capabilities.contains(.heartRate) }
                        let powerDevices = bluetoothManager.peripherals.filter { $0.capabilities.contains(.cyclingPower) }
                        let trainerDevices = bluetoothManager.peripherals.filter { $0.capabilities.contains(.fitnessMachine) }
                        let otherDevices = bluetoothManager.peripherals.filter { $0.capabilities.isEmpty }
                        
                        if !hrDevices.isEmpty {
                            Section("Heart Rate Monitors") {
                                ForEach(hrDevices) { peripheral in
                                    DeviceRowView(peripheral: peripheral)
                                }
                            }
                        }
                        
                        if !powerDevices.isEmpty {
                            Section("Power Meters") {
                                ForEach(powerDevices) { peripheral in
                                    DeviceRowView(peripheral: peripheral)
                                }
                            }
                        }
                        
                        if !trainerDevices.isEmpty {
                            Section("Smart Trainers") {
                                ForEach(trainerDevices) { peripheral in
                                    DeviceRowView(peripheral: peripheral)
                                }
                            }
                        }
                        
                        if !otherDevices.isEmpty {
                            Section("Other Devices") {
                                ForEach(otherDevices) { peripheral in
                                    DeviceRowView(peripheral: peripheral)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Devices")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        if bluetoothManager.isScanning {
                            Button("Stop") {
                                bluetoothManager.stopScanning()
                            }
                        }
                    }
                }
            }
            .tabItem {
                Label("Devices", systemImage: "antenna.radiowaves.left.and.right")
            }
            
            WorkoutPlayerView()
                .tabItem {
                    Label("Workout", systemImage: "play.circle")
                }
            
            HRComparisonView()
                .tabItem {
                    Label("HR Compare", systemImage: "heart.square")
                }
                
            PowerComparisonView()
                .tabItem {
                    Label("Power Compare", systemImage: "bolt.square")
                }
        }
    }
}

struct DeviceRowView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @ObservedObject var peripheral: DiscoveredPeripheral
    
    var body: some View {
        NavigationLink(destination: DeviceDetailView(peripheral: peripheral)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(peripheral.name)
                        .font(.headline)
                    Text(peripheral.id.uuidString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if peripheral.isConnected {
                    Button("Disconnect") {
                        bluetoothManager.disconnect(peripheral: peripheral)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    // Prevent button click from triggering NavigationLink
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                } else {
                    Button("Connect") {
                        bluetoothManager.connect(peripheral: peripheral)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct DeviceDetailView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    @ObservedObject var peripheral: DiscoveredPeripheral
    @State private var showDebug = false

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("State")
                    Spacer()
                    if peripheral.isConnected {
                        Text("Connected")
                            .foregroundColor(.green)
                            .bold()
                    } else {
                        Text("Disconnected")
                            .foregroundColor(.secondary)
                    }
                }
                
                if peripheral.isConnected {
                    Button("Disconnect") {
                        bluetoothManager.disconnect(peripheral: peripheral)
                    }
                    .foregroundColor(.red)
                } else {
                    Button("Connect") {
                        bluetoothManager.connect(peripheral: peripheral)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if peripheral.isConnected {
                Section("Live Data") {
                    if let hr = peripheral.heartRate {
                        HStack {
                            Label("Heart Rate", systemImage: "heart.fill")
                                .foregroundColor(.red)
                            Spacer()
                            Text("\(hr) BPM")
                                .font(.title3)
                                .bold()
                        }
                    }
                    
                    if let dfa = peripheral.dfaAlpha1 {
                        HStack {
                            Label("DFA-a1", systemImage: "waveform.path.ecg")
                                .foregroundColor(.purple)
                            Spacer()
                            Text(String(format: "%.2f", dfa))
                                .font(.headline)
                                .foregroundColor(dfa > 0.75 ? .green : .orange)
                        }
                    }
                    
                    if let power = peripheral.cyclingPower {
                        HStack {
                            Label("Cycling Power", systemImage: "bolt.fill")
                                .foregroundColor(.yellow)
                            Spacer()
                            Text("\(power) W")
                                .font(.title3)
                                .bold()
                        }
                    }
                    
                    if let balance = peripheral.powerBalance {
                        HStack {
                            Label("Power Balance (L/R)", systemImage: "scale.3d")
                                .foregroundColor(.orange)
                            Spacer()
                            Text(String(format: "%.1f%% L / %.1f%% R", balance, 100.0 - balance))
                                .font(.subheadline)
                        }
                    }
                    
                    if let cadence = peripheral.cadence {
                        HStack {
                            Label("Cadence", systemImage: "bicycle")
                                .foregroundColor(.blue)
                            Spacer()
                            Text("\(cadence) RPM")
                                .font(.title3)
                                .bold()
                        }
                    }
                }
                
                Section("Device Information") {
                    if let manufacturer = peripheral.manufacturerName {
                        HStack {
                            Text("Manufacturer")
                            Spacer()
                            Text(manufacturer).foregroundColor(.secondary)
                        }
                    }
                    
                    if let model = peripheral.modelNumber {
                        HStack {
                            Text("Model")
                            Spacer()
                            Text(model).foregroundColor(.secondary)
                        }
                    }
                    
                    if let firmware = peripheral.firmwareRevision {
                        HStack {
                            Text("Firmware")
                            Spacer()
                            Text(firmware).foregroundColor(.secondary)
                        }
                    }
                    
                    if let battery = peripheral.batteryLevel {
                        HStack {
                            Text("Battery Level")
                            Spacer()
                            Text("\(battery)%")
                                .foregroundColor(battery > 20 ? .green : .red)
                        }
                    }
                }
                
                Section {
                    Toggle("Show Debug Info", isOn: $showDebug)
                }
                
                if showDebug {
                    Section("Debug Information") {
                        if let hex = peripheral.rawDataHex {
                            VStack(alignment: .leading) {
                                Text("Last Raw Data:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(hex)
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                        
                        if !peripheral.rrIntervalsHistory.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Recent RR Intervals (s) (Total: \(peripheral.rrIntervalsHistory.count)):")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(Array(peripheral.rrIntervalsHistory.suffix(20).enumerated()), id: \.offset) { _, rr in
                                            Text(String(format: "%.3f", rr))
                                                .padding(4)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                .font(.system(.caption, design: .monospaced))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(peripheral.name)
    }
}
