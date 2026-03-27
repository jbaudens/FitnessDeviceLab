import SwiftUI
import CoreBluetooth

struct DevicesTabView: View {
    @Bindable var viewModel: DevicesViewModel
    
    var body: some View {
        DevicesListContent(viewModel: viewModel)
    }
}

struct DevicesListContent: View {
    @Bindable var viewModel: DevicesViewModel
    
    var body: some View {
        List {
            Section {
                headerSection
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            
            if viewModel.peripherals.isEmpty {
                Section {
                    emptyStateView
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity, minHeight: 400)
                }
            } else {
                Section {
                    ForEach(viewModel.peripherals, id: \.id) { peripheral in
                        PeripheralCardView(peripheral: peripheral, viewModel: viewModel)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .adaptiveListStyle()
        .navigationTitle("Devices")
        .background(Color.systemGroupedBackground)
        .hideNavigationBarOnMobile()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BLUETOOTH STATUS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.bluetoothManager.state == .poweredOn ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(stateDescription.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                }
                
                Spacer()
                
                #if DEBUG
                // Dev-only Add Fake Device Button
                Button(action: { viewModel.addSimulatedDevice(name: "Virtual Trainer \(viewModel.peripherals.count + 1)") }) {
                    Label("Add Virtual", systemImage: "plus.circle")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .controlSize(.small)
                .accessibilityIdentifier("add_virtual_device")
                #endif
            }
            
            HStack {
                if viewModel.isScanning {
                    Button(role: .destructive, action: { viewModel.stopScanning() }) {
                        Label("Stop Scanning", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("stop_scanning")
                } else {
                    Button(action: { viewModel.startScanning() }) {
                        Label("Search for Devices", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.bluetoothManager.state != .poweredOn)
                    .accessibilityIdentifier("start_scanning")
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Devices Discovered")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Ensure your sensors are awake and nearby, then tap Search.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var stateDescription: String {
        switch viewModel.bluetoothManager.state {
        case .poweredOn: return "Ready"
        case .poweredOff: return "Powered Off"
        case .unauthorized: return "Unauthorized"
        case .unsupported: return "Unsupported"
        case .resetting: return "Resetting..."
        default: return "Initializing..."
        }
    }
}

struct PeripheralCardView: View {
    let peripheral: any SensorPeripheral
    let viewModel: DevicesViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(peripheral.name)
                            .font(.headline)
                        
                        if peripheral is SimulatedPeripheral {
                            Text("VIRTUAL")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if peripheral.capabilities.contains(.heartRate) { capabilityBadge(icon: "heart.fill", color: .red) }
                        if peripheral.capabilities.contains(.cyclingPower) { capabilityBadge(icon: "bolt.fill", color: .yellow) }
                        if peripheral.capabilities.contains(.cadence) { capabilityBadge(icon: "bicycle", color: .blue) }
                        if peripheral.capabilities.contains(.fitnessMachine) { capabilityBadge(icon: "cpu", color: .green) }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if peripheral is SimulatedPeripheral {
                        Button(role: .destructive, action: { viewModel.removeSimulatedDevice(id: peripheral.id) }) {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Button(action: { viewModel.toggleConnection(for: peripheral) }) {
                        Text(peripheral.isConnected ? "Disconnect" : "Connect")
                            .fontWeight(.bold)
                    }
                    .buttonStyle(.bordered)
                    .tint(peripheral.isConnected ? .red : .blue)
                    .controlSize(.small)
                    .accessibilityIdentifier("connect_button_\(peripheral.name.replacingOccurrences(of: " ", with: "_").lowercased())")
                }
            }
            .padding()
            
            if peripheral.isConnected {
                Divider().padding(.horizontal)
                
                HStack(spacing: 20) {
                    if let hr = viewModel.hrSensor(for: peripheral) {
                        inlineMetric(value: "\(hr.heartRate ?? 0)", unit: "bpm", icon: "heart.fill", color: .red)
                    }
                    if let pwr = viewModel.powerSensor(for: peripheral) {
                        inlineMetric(value: "\(pwr.cyclingPower ?? 0)", unit: "w", icon: "bolt.fill", color: .yellow)
                    }
                    if let cad = viewModel.cadenceSensor(for: peripheral) {
                        inlineMetric(value: "\(cad.cadence ?? 0)", unit: "rpm", icon: "bicycle", color: .blue)
                    }
                    
                    Spacer()
                    
                    if let disc = peripheral as? DiscoveredPeripheral, let battery = disc.batteryLevel {
                        VStack(spacing: 2) {
                            Image(systemName: "battery.100")
                                .foregroundColor(battery > 20 ? .green : .red)
                            Text("\(battery)%").font(.system(size: 8, weight: .bold))
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.03))
            }
        }
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(peripheral.isConnected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 2)
    }

    
    private func capabilityBadge(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 8))
            .padding(4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(Circle())
    }
    
    private func inlineMetric(value: String, unit: String, icon: String, color: Color) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded))
            Text(unit).font(.system(size: 10, weight: .black)).foregroundColor(.secondary)
        }
    }
}

#Preview("Devices Tab") {
    let settings = SettingsManager()
    let errorManager = ErrorManager()
    let bluetooth = BluetoothManager(settings: settings, errorManager: errorManager)
    let viewModel = DevicesViewModel(bluetoothManager: bluetooth)
    
    NavigationStack {
        DevicesTabView(viewModel: viewModel)
    }
}

#Preview("Peripheral Card") {
    let settings = SettingsManager()
    let errorManager = ErrorManager()
    let bluetooth = BluetoothManager(settings: settings, errorManager: errorManager)
    let viewModel = DevicesViewModel(bluetoothManager: bluetooth)
    let peripheral = SimulatedPeripheral(name: "Wahoo KICKR", settings: settings)
    
    VStack {
        PeripheralCardView(peripheral: peripheral, viewModel: viewModel)
            .padding()
        
        let connectedPeripheral = SimulatedPeripheral(name: "Garmin HRM", settings: settings)
        let _ = {
            connectedPeripheral.isConnected = true
            connectedPeripheral.heartRate = 145
            return true
        }()
        
        PeripheralCardView(peripheral: connectedPeripheral, viewModel: viewModel)
            .padding()
    }
    .background(Color.systemGroupedBackground)
}
