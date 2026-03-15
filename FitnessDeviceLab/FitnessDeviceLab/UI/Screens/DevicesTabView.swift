import SwiftUI

struct DevicesTabView: View {
    @Environment(\.bluetoothProvider) var bluetoothProvider
    @State private var viewModel: DevicesViewModel?
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                DevicesListContent(viewModel: viewModel)
            } else {
                ProgressView().onAppear {
                    viewModel = DevicesViewModel(bluetoothProvider: bluetoothProvider)
                }
            }
        }
    }
}

struct DevicesListContent: View {
    @Bindable var viewModel: DevicesViewModel
    
    var body: some View {
        VStack {
            if viewModel.bluetoothProvider.isScanning {
                ProgressView("Scanning for devices...")
                    .padding()
            } else {
                Button("Scan for Devices") {
                    viewModel.startScanning()
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }

            List {
                if !viewModel.hrDevices.isEmpty {
                    Section("Heart Rate Monitors") {
                        ForEach(viewModel.hrDevices, id: \.id) { peripheral in
                            AnyDeviceRowView(peripheral: peripheral, viewModel: viewModel)
                        }
                    }
                }
                
                if !viewModel.powerDevices.isEmpty {
                    Section("Power Meters") {
                        ForEach(viewModel.powerDevices, id: \.id) { peripheral in
                            AnyDeviceRowView(peripheral: peripheral, viewModel: viewModel)
                        }
                    }
                }
                
                if !viewModel.trainerDevices.isEmpty {
                    Section("Smart Trainers") {
                        ForEach(viewModel.trainerDevices, id: \.id) { peripheral in
                            AnyDeviceRowView(peripheral: peripheral, viewModel: viewModel)
                        }
                    }
                }
                
                if !viewModel.otherDevices.isEmpty {
                    Section("Other Devices") {
                        ForEach(viewModel.otherDevices, id: \.id) { peripheral in
                            AnyDeviceRowView(peripheral: peripheral, viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .navigationTitle("Devices")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.bluetoothProvider.isScanning {
                    Button("Stop") {
                        viewModel.stopScanning()
                    }
                }
            }
        }
    }
}

struct AnyDeviceRowView: View {
    let peripheral: any SensorPeripheral
    let viewModel: DevicesViewModel
    
    var body: some View {
        if let disc = peripheral as? DiscoveredPeripheral {
            DeviceRowView(peripheral: disc, viewModel: viewModel)
        } else if let sim = peripheral as? SimulatedPeripheral {
            SimDeviceRowView(peripheral: sim, viewModel: viewModel)
        }
    }
}

struct DeviceRowView: View {
    @Bindable var peripheral: DiscoveredPeripheral
    let viewModel: DevicesViewModel
    
    var body: some View {
        NavigationLink(destination: DeviceDetailView(peripheral: peripheral, viewModel: viewModel)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(peripheral.name)
                        .font(.headline)
                    Text(peripheral.id.uuidString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                connectionButton(for: peripheral)
            }
        }
    }
    
    @ViewBuilder
    func connectionButton(for p: any SensorPeripheral) -> some View {
        Button {
            viewModel.toggleConnection(for: p)
        } label: {
            Text(p.isConnected ? "Disconnect" : "Connect")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(p.isConnected ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(p.isConnected ? .red : .blue)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct SimDeviceRowView: View {
    @Bindable var peripheral: SimulatedPeripheral
    let viewModel: DevicesViewModel
    
    var body: some View {
        NavigationLink(destination: SimDeviceDetailView(peripheral: peripheral, viewModel: viewModel)) {
            HStack {
                VStack(alignment: .leading) {
                    Text(peripheral.name)
                        .font(.headline)
                    Text("SIMULATED")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
                
                Button {
                    viewModel.toggleConnection(for: peripheral)
                } label: {
                    Text(peripheral.isConnected ? "Disconnect" : "Connect")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(peripheral.isConnected ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .foregroundColor(peripheral.isConnected ? .red : .blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DeviceDetailView: View {
    @Bindable var peripheral: DiscoveredPeripheral
    let viewModel: DevicesViewModel
    @State private var showDebug = false

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("State")
                    Spacer()
                    if peripheral.isConnected {
                        Text("Connected").foregroundColor(.green).bold()
                    } else {
                        Text("Disconnected").foregroundColor(.secondary)
                    }
                }
                
                Button(peripheral.isConnected ? "Disconnect" : "Connect") {
                    viewModel.toggleConnection(for: peripheral)
                }
                .foregroundColor(peripheral.isConnected ? .red : .blue)
            }
            
            if peripheral.isConnected {
                Section("Live Data") {
                    if let hr = peripheral.heartRate {
                        MetricRow(label: "Heart Rate", value: "\(hr) BPM", icon: "heart.fill", color: .red)
                    }
                    if let power = peripheral.cyclingPower {
                        MetricRow(label: "Cycling Power", value: "\(power) W", icon: "bolt.fill", color: .yellow)
                    }
                    if let balance = peripheral.powerBalance {
                        MetricRow(label: "Balance", value: String(format: "%.1f%% L/R", balance), icon: "scale.3d", color: .orange)
                    }
                    if let cadence = peripheral.cadence {
                        MetricRow(label: "Cadence", value: "\(cadence) RPM", icon: "bicycle", color: .blue)
                    }
                }
                
                Section("Device Information") {
                    InfoRow(label: "Manufacturer", value: peripheral.manufacturerName)
                    InfoRow(label: "Model", value: peripheral.modelNumber)
                    InfoRow(label: "Firmware", value: peripheral.firmwareRevision)
                    if let battery = peripheral.batteryLevel {
                        HStack {
                            Text("Battery Level")
                            Spacer()
                            Text("\(battery)%").foregroundColor(battery > 20 ? .green : .red)
                        }
                    }
                }
                
                Toggle("Show Debug Info", isOn: $showDebug)
                
                if showDebug, let hex = peripheral.rawDataHex {
                    Section("Debug Information") {
                        Text(hex).font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle(peripheral.name)
    }
}

struct SimDeviceDetailView: View {
    @Bindable var peripheral: SimulatedPeripheral
    let viewModel: DevicesViewModel

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("State")
                    Spacer()
                    Text(peripheral.isConnected ? "Connected" : "Disconnected")
                        .foregroundColor(peripheral.isConnected ? .green : .secondary)
                }
                Button(peripheral.isConnected ? "Disconnect" : "Connect") {
                    viewModel.toggleConnection(for: peripheral)
                }
                .foregroundColor(peripheral.isConnected ? .red : .blue)
            }
            
            if peripheral.isConnected {
                Section("Simulated Live Data") {
                    MetricRow(label: "Heart Rate", value: "\(peripheral.heartRate ?? 0) BPM", icon: "heart.fill", color: .red)
                    MetricRow(label: "Cycling Power", value: "\(peripheral.cyclingPower ?? 0) W", icon: "bolt.fill", color: .yellow)
                    MetricRow(label: "Cadence", value: "\(peripheral.cadence ?? 0) RPM", icon: "bicycle", color: .blue)
                }
            }
        }
        .navigationTitle(peripheral.name)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        HStack {
            Label(label, systemImage: icon).foregroundColor(color)
            Spacer()
            Text(value).font(.title3).bold()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String?
    var body: some View {
        if let value = value {
            HStack {
                Text(label)
                Spacer()
                Text(value).foregroundColor(.secondary)
            }
        }
    }
}
