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
    
    func deviceNames(hr: DiscoveredPeripheral?, pwr: DiscoveredPeripheral?) -> String {
        let names = [hr?.name, pwr?.name].compactMap { $0 }
        let uniqueNames = Array(Set(names))
        return uniqueNames.isEmpty ? "No Sensors" : uniqueNames.joined(separator: " + ")
    }
    
    var body: some View {
        Group {
            if workoutManager.isRecording {
                // Recording View
                VStack(spacing: 0) {
                    TabView {
                        ForEach(workoutManager.activeProfile.pages) { page in
                            ScrollView {
                                VStack(spacing: 24) {
                                    // Primary Sensor Set
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Label("SET A", systemImage: "1.circle.fill")
                                            Spacer()
                                            Text(deviceNames(hr: hrA, pwr: powerA))
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        }
                                        .font(.caption)
                                        .fontWeight(.black)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal)
                                        
                                        MetricGraphView(recorder: workoutManager.recorderA)
                                            .padding(.horizontal)
                                        
                                        DataFieldGrid(
                                            recorder: workoutManager.recorderA,
                                            fields: page.fields
                                        )
                                        .padding(.horizontal)
                                    }
                                    
                                    Divider().padding(.horizontal)
                                    
                                    // Secondary Sensor Set
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Label("SET B", systemImage: "2.circle.fill")
                                            Spacer()
                                            Text(deviceNames(hr: hrB, pwr: powerB))
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        }
                                        .font(.caption)
                                        .fontWeight(.black)
                                        .foregroundColor(.purple)
                                        .padding(.horizontal)
                                        
                                        MetricGraphView(recorder: workoutManager.recorderB)
                                            .padding(.horizontal)
                                        
                                        DataFieldGrid(
                                            recorder: workoutManager.recorderB,
                                            fields: page.fields
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
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
                            // Profile Header
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Workout Setup")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text(workoutManager.activeProfile.name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Clear All") {
                                    workoutManager.hrDeviceAId = nil
                                    workoutManager.powerDeviceAId = nil
                                    workoutManager.hrDeviceBId = nil
                                    workoutManager.powerDeviceBId = nil
                                    workoutManager.selectedWorkout = nil
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                            .padding(.bottom, 8)
                            
                            // Selected Workout Card
                            if let workout = workoutManager.selectedWorkout {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("SELECTED WORKOUT")
                                            .font(.caption)
                                            .fontWeight(.black)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Button(action: { workoutManager.selectedWorkout = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Text(workout.name)
                                        .font(.headline)
                                    
                                    WorkoutGraphView(workout: workout, showAxis: false)
                                        .frame(height: 60)
                                        .padding(.vertical, 4)
                                    
                                    Text(workout.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                            }

                            // Sensor Selection Cards
                            SensorSetCard(
                                title: "PRIMARY RECORDER (A)",
                                subtitle: "Used for primary display & stats",
                                color: .blue,
                                hrId: $workoutManager.hrDeviceAId,
                                powerId: $workoutManager.powerDeviceAId,
                                hrDevices: hrDevices,
                                powerDevices: powerDevices
                            )
                            
                            SensorSetCard(
                                title: "SECONDARY RECORDER (B)",
                                subtitle: "Background comparison recording",
                                color: .purple,
                                hrId: $workoutManager.hrDeviceBId,
                                powerId: $workoutManager.powerDeviceBId,
                                hrDevices: hrDevices,
                                powerDevices: powerDevices
                            )
                            
                            // Recording Controls
                            VStack(spacing: 12) {
                                Button(action: {
                                    workoutManager.startWorkout(devices: bluetoothManager.peripherals)
                                }) {
                                    Label("Start Recording", systemImage: "play.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(workoutManager.hrDeviceAId == nil && workoutManager.powerDeviceAId == nil && workoutManager.hrDeviceBId == nil && workoutManager.powerDeviceBId == nil)
                                
                                if !workoutManager.exportedFiles.isEmpty {
                                    ShareLink(items: workoutManager.exportedFiles) {
                                        Label("Export Last Workout (.TCX)", systemImage: "square.and.arrow.up")
                                            .font(.subheadline)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.blue)
                                }
                            }
                            .padding(.top)
                        }
                    }
                    .padding()
                }
                .navigationTitle("New Session")
            }
        }
    }
}

struct SensorSetCard: View {
    let title: String
    let subtitle: String
    let color: Color
    @Binding var hrId: UUID?
    @Binding var powerId: UUID?
    let hrDevices: [DiscoveredPeripheral]
    let powerDevices: [DiscoveredPeripheral]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                // HR Picker
                HStack {
                    Label {
                        Text("Heart Rate")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Picker("HR", selection: $hrId) {
                        Text("Unassigned").tag(UUID?.none)
                        ForEach(hrDevices) { device in
                            Text(device.name).tag(UUID?.some(device.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                // Power Picker
                HStack {
                    Label {
                        Text("Power Meter")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                    
                    Picker("Power", selection: $powerId) {
                        Text("Unassigned").tag(UUID?.none)
                        ForEach(powerDevices) { device in
                            Text(device.name).tag(UUID?.some(device.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
