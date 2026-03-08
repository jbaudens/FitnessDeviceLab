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
                    // Active Workout Header (Summary targets)
                    if let workout = workoutManager.selectedWorkout {
                        WorkoutTargetHeader(workout: workout)
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                    }
                    
                    TabView {
                        // Data Pages
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
                                        
                                        if let workout = workoutManager.selectedWorkout {
                                            WorkoutGraphView(
                                                workout: workout,
                                                elapsedTime: workoutManager.workoutElapsedTime,
                                                recorder: workoutManager.recorderA
                                            )
                                            .frame(height: 140)
                                            .padding(8)
                                            .background(Color.secondary.opacity(0.05))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                        }
                                        
                                        DataFieldGrid(
                                            engine: workoutManager.engineA,
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
                                        
                                        if let workout = workoutManager.selectedWorkout {
                                            WorkoutGraphView(
                                                workout: workout,
                                                elapsedTime: workoutManager.workoutElapsedTime,
                                                recorder: workoutManager.recorderB
                                            )
                                            .frame(height: 140)
                                            .padding(8)
                                            .background(Color.secondary.opacity(0.05))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                        }
                                        
                                        DataFieldGrid(
                                            engine: workoutManager.engineB,
                                            fields: page.fields
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                        
                        // Laps View
                        LapsHistoryView()
                    }
                    #if os(iOS)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    #endif
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            workoutManager.manualLap()
                        }) {
                            Label("Lap", systemImage: "circle.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
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
                    }
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

struct WorkoutTargetHeader: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    let workout: StructuredWorkout
    
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .medium
        return df
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                // Time in Interval
                if let step = workoutManager.currentWorkoutStep {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(formatDuration(step.duration - workoutManager.timeInStep))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("LAP \(workoutManager.laps.count)")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.blue)
                                Text(formatDuration(workoutManager.laps.last?.duration ?? 0))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text("REMAINING IN STEP")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Target Power
                    VStack(alignment: .trailing, spacing: 2) {
                        let targetWatts = Int(round(step.targetPowerPercent * SettingsManager.shared.userFTP))
                        Text("\(targetWatts)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(WorkoutZone.forIntensity(step.targetPowerPercent).color)
                        Text("TARGET WATTS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 12) {
                Picker("Mode", selection: $workoutManager.currentDataFieldMode) {
                    ForEach(WorkoutSessionManager.DataFieldMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
                Spacer()
                
                Label("Power", systemImage: "bolt.fill").foregroundColor(.yellow)
                Label("Cadence", systemImage: "bicycle").foregroundColor(.blue)
                Label("HR", systemImage: "heart.fill").foregroundColor(.red)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                HStack {
                    if let start = workoutManager.sessionStartTime {
                        Text("Started: \(timeFormatter.string(from: start))")
                        Spacer()
                        let expectedEnd = start.addingTimeInterval(workout.totalDuration)
                        Text("Ends: \(timeFormatter.string(from: expectedEnd))")
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

                HStack {
                    Spacer()
                    Text("Total: \(formatDuration(workoutManager.workoutElapsedTime)) / \(formatDuration(workout.totalDuration))")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.primary)
                }
            }
            
            if workoutManager.currentStepIndex < workout.steps.count - 1 {
                let nextStep = workout.steps[workoutManager.currentStepIndex + 1]
                HStack {
                    Spacer()
                    Text("Next: \(Int(nextStep.targetPowerPercent * 100))% for \(Int(nextStep.duration / 60))m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct LapsHistoryView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .medium
        return df
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Laps History")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(workoutManager.laps.reversed()) { lap in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Lap \(lap.index + 1)")
                                .fontWeight(.bold)
                            
                            Text(lap.type.rawValue.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)

                            if lap.index == workoutManager.laps.count - 1 {
                                Text("CURRENT")
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(timeFormatter.string(from: lap.startTime))
                                    Text("-")
                                    if let end = lap.endTime {
                                        Text(timeFormatter.string(from: end))
                                    } else {
                                        Text("Now")
                                    }
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                
                                Text("Duration: \(formatDuration(lap.duration))")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .monospacedDigit()
                        
                        // Lap Summary Table (A vs B)
                        HStack(spacing: 20) {
                            LapSummaryColumn(label: "SET A", recorder: workoutManager.recorderA, lapIndex: lap.index, color: .blue)
                            Divider()
                            LapSummaryColumn(label: "SET B", recorder: workoutManager.recorderB, lapIndex: lap.index, color: .purple)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct LapSummaryColumn: View {
    let label: String
    let recorder: SessionRecorder
    let lapIndex: Int
    let color: Color
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    
    var body: some View {
        let lap = workoutManager.laps[lapIndex]
        let points = recorder.trackpoints.filter { 
            $0.time >= lap.startTime && (lap.endTime == nil || $0.time < lap.endTime!)
        }
        let m = DataFieldEngine.calculate(from: points, settings: SettingsManager.shared.metricsSettings)
        
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                // Power row
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").foregroundColor(.yellow)
                    Text("\(Int(round(m.standard.avgPower ?? 0)))").bold()
                    Text("[\(m.standard.minPower ?? 0)-\(m.standard.maxPower ?? 0)]").font(.caption2).foregroundColor(.secondary)
                    if let np = m.standard.normalizedPower {
                        Text("NP: \(Int(round(np)))").font(.caption2).foregroundColor(.orange)
                    }
                }
                
                // HR row
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").foregroundColor(.red)
                    Text("\(Int(round(m.hr.avg ?? 0)))").bold()
                    Text("[\(m.hr.min ?? 0)-\(m.hr.max ?? 0)]").font(.caption2).foregroundColor(.secondary)
                }
                
                // Cadence row
                HStack(spacing: 4) {
                    Image(systemName: "bicycle").foregroundColor(.blue)
                    Text("\(Int(round(m.cadence.avg ?? 0)))").bold()
                    Text("[\(m.cadence.min ?? 0)-\(m.cadence.max ?? 0)]").font(.caption2).foregroundColor(.secondary)
                }
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
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
