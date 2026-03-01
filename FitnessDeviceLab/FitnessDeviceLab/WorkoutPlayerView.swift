import SwiftUI

struct WorkoutPlayerView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    
    var hrDevices: [DiscoveredPeripheral] {
        bluetoothManager.peripherals.filter { $0.capabilities.contains(.heartRate) && $0.isConnected }
    }
    var powerDevices: [DiscoveredPeripheral] {
        bluetoothManager.peripherals.filter { 
            ($0.capabilities.contains(.cyclingPower) || $0.capabilities.contains(.fitnessMachine)) && $0.isConnected 
        }
    }
    
    var hrA: DiscoveredPeripheral? { hrDevices.first { $0.id == workoutManager.hrDeviceAId } }
    var powerA: DiscoveredPeripheral? { powerDevices.first { $0.id == workoutManager.powerDeviceAId } }
    
    var hrB: DiscoveredPeripheral? { hrDevices.first { $0.id == workoutManager.hrDeviceBId } }
    var powerB: DiscoveredPeripheral? { powerDevices.first { $0.id == workoutManager.powerDeviceBId } }
    
    var body: some View {
        NavigationStack {
            if workoutManager.isRecording {
                // Recording View (Garmin-style Pages)
                VStack {
                    TabView {
                        ForEach(workoutManager.activeProfile.pages) { page in
                            ScrollView {
                                DataFieldGrid(
                                    hrPeripheral: hrA,
                                    powerPeripheral: powerA,
                                    fields: page.fields
                                )
                                .padding()
                            }
                        }
                    }
                    #if os(iOS)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    #endif
                    
                    Button(action: {
                        workoutManager.stopWorkout()
                    }) {
                        Label("Stop Recording", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding()
                }
                .navigationTitle(workoutManager.activeProfile.name)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            } else {
                // Setup View
                ScrollView {
                    VStack(spacing: 24) {
                        if hrDevices.isEmpty && powerDevices.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "sensor.tag.radiowaves.forward")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No Connected Sensors")
                                    .font(.headline)
                                Text("Connect to HR monitors or power sources from the Devices tab.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        } else {
                            // Profile Setup
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Activity Profile")
                                        .font(.headline)
                                    Spacer()
                                    // Could add a navigation link to a profile editor here
                                    Text(workoutManager.activeProfile.name)
                                        .foregroundColor(.secondary)
                                }
                                Divider()
                                
                                Text("Primary Sensors (Recorded & Displayed)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                
                                HStack {
                                    Image(systemName: "heart.fill").foregroundColor(.red)
                                    Picker("HR", selection: $workoutManager.hrDeviceAId) {
                                        Text("None").tag(UUID?.none)
                                        ForEach(hrDevices) { device in Text(device.name).tag(UUID?.some(device.id)) }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                HStack {
                                    Image(systemName: "bolt.fill").foregroundColor(.yellow)
                                    Picker("Power", selection: $workoutManager.powerDeviceAId) {
                                        Text("None").tag(UUID?.none)
                                        ForEach(powerDevices) { device in Text(device.name).tag(UUID?.some(device.id)) }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Secondary Profile Setup
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Secondary Sensors (Background Recording)")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                
                                HStack {
                                    Image(systemName: "heart.fill").foregroundColor(.red)
                                    Picker("HR", selection: $workoutManager.hrDeviceBId) {
                                        Text("None").tag(UUID?.none)
                                        ForEach(hrDevices) { device in Text(device.name).tag(UUID?.some(device.id)) }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                HStack {
                                    Image(systemName: "bolt.fill").foregroundColor(.yellow)
                                    Picker("Power", selection: $workoutManager.powerDeviceBId) {
                                        Text("None").tag(UUID?.none)
                                        ForEach(powerDevices) { device in Text(device.name).tag(UUID?.some(device.id)) }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Recording Controls
                            VStack {
                                Button(action: {
                                    workoutManager.startWorkout(devices: bluetoothManager.peripherals)
                                }) {
                                    Label("Start Workout", systemImage: "play.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                
                                if !workoutManager.exportedFiles.isEmpty {
                                    ShareLink(items: workoutManager.exportedFiles) {
                                        Label("Export Last Workout (.TCX)", systemImage: "square.and.arrow.up")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.top)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Workout Setup")
            }
        }
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
