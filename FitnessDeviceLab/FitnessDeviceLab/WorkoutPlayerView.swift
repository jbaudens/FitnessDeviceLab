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
    
    @State private var showingStopConfirmation = false
    
    func deviceNames(pwr: DiscoveredPeripheral?, hr: DiscoveredPeripheral?) -> String {
        let names = [pwr?.name, hr?.name].compactMap { $0 }
        let uniqueNames = names.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        return uniqueNames.isEmpty ? "No Sensors" : uniqueNames.joined(separator: " + ")
    }
    
    var body: some View {
        Group {
            if workoutManager.isLoaded || workoutManager.isRecording {
                activeView
            } else {
                setupView
            }
        }
    }
    
    private var activeView: some View {
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
                            sensorSetSection(title: "SET A", color: .blue, pwr: powerA, hr: hrA, recorder: workoutManager.recorderA, fields: page.fields)
                            Divider().padding(.horizontal)
                            sensorSetSection(title: "SET B", color: .purple, pwr: powerB, hr: hrB, recorder: workoutManager.recorderB, fields: page.fields)
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
            
            activeControls
        }
        .navigationTitle(workoutManager.activeProfile.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func sensorSetSection(title: String, color: Color, pwr: DiscoveredPeripheral?, hr: DiscoveredPeripheral?, recorder: SessionRecorder, fields: [DataFieldType]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: title == "SET A" ? "1.circle.fill" : "2.circle.fill")
                Spacer()
                Text(deviceNames(pwr: pwr, hr: hr))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .font(.caption)
            .fontWeight(.black)
            .foregroundColor(color)
            .padding(.horizontal)
            
            if let workout = workoutManager.selectedWorkout {
                WorkoutGraphView(
                    workout: workout,
                    elapsedTime: workoutManager.workoutElapsedTime,
                    recorder: recorder,
                    scale: workoutManager.workoutDifficultyScale
                )
                .frame(height: 140)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            DataFieldGrid(
                engine: title == "SET A" ? workoutManager.engineA : workoutManager.engineB,
                fields: fields
            )
            .padding(.horizontal)
        }
    }
    
    private var activeControls: some View {
        HStack(spacing: 16) {
            if !workoutManager.isRecording {
                Button(action: {
                    workoutManager.isLoaded = false
                    workoutManager.isRecording = false
                }) {
                    Label("Cancel", systemImage: "xmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                
                Button(action: {
                    workoutManager.startRecording()
                }) {
                    Label("Start Recording", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
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
                .disabled(workoutManager.isPaused)
                
                Button(action: {
                    if workoutManager.isPaused {
                        workoutManager.resumeWorkout()
                    } else {
                        workoutManager.pauseWorkout()
                    }
                }) {
                    Label(workoutManager.isPaused ? "Resume" : "Pause", systemImage: workoutManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button(action: {
                    showingStopConfirmation = true
                }) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert("Stop Workout?", isPresented: $showingStopConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Stop & Save", role: .destructive) {
                        workoutManager.stopWorkout()
                    }
                } message: {
                    Text("This will end the current session and save the data.")
                }
            }
        }
        .padding()
    }
    
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if hrDevices.isEmpty && powerDevices.isEmpty {
                    emptySensorsView
                } else {
                    setupContent
                }
            }
            .padding()
        }
        .navigationTitle("New Session")
    }
    
    private var emptySensorsView: some View {
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
    }
    
    private var setupContent: some View {
        VStack(spacing: 24) {
            setupHeader
            
            if let workout = workoutManager.selectedWorkout {
                selectedWorkoutCard(workout: workout)
            }

            if workoutManager.isLoaded && !workoutManager.isRecording {
                liveDataPreview
            }

            sensorSelectionSection
            
            setupControls
        }
    }
    
    private var setupHeader: some View {
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
    }
    
    private var sensorSelectionSection: some View {
        VStack(spacing: 24) {
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
        }
    }
    
    private func selectedWorkoutCard(workout: StructuredWorkout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SELECTED WORKOUT")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.blue)
                Spacer()
                
                // Mode Selection Dropdown
                Menu {
                    Button(action: { workoutManager.ergModeEnabled = true }) {
                        HStack {
                            Text("ERG Mode")
                            if workoutManager.ergModeEnabled { Image(systemName: "checkmark") }
                        }
                    }
                    .disabled(!workoutManager.canEnableErgMode)
                    
                    Button(action: { workoutManager.ergModeEnabled = false }) {
                        HStack {
                            Text("Resistance Mode")
                            if !workoutManager.ergModeEnabled { Image(systemName: "checkmark") }
                        }
                    }
                    .disabled(!workoutManager.canEnableErgMode)
                } label: {
                    Text(workoutManager.ergModeEnabled ? "ERG" : "RES")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(workoutManager.ergModeEnabled ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .padding(.trailing, 8)
                
                if !workoutManager.ergModeEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "plusminus")
                            .font(.system(size: 8))
                        Slider(value: $workoutManager.resistanceLevel, in: 0...100, step: 1)
                            .frame(width: 80)
                            .disabled(!workoutManager.canEnableErgMode)
                        Text("\(Int(workoutManager.resistanceLevel))%")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                    .padding(.trailing, 8)
                }
                
                Button(action: { workoutManager.selectedWorkout = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(workout.name)
                .font(.headline)
            
            WorkoutGraphView(workout: workout, showAxis: false, scale: workoutManager.workoutDifficultyScale)
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
    
    private var liveDataPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIVE DATA PREVIEW")
                .font(.caption)
                .fontWeight(.black)
                .foregroundColor(.orange)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("HEART RATE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(workoutManager.recorderA.hrDevice?.heartRate ?? 0)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("BPM")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("POWER")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.secondary)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(workoutManager.recorderA.powerDevice?.cyclingPower ?? 0)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("W")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if (workoutManager.recorderA.powerDevice?.cyclingPower ?? 0) > 0 {
                    Label("Pedaling Detected", systemImage: "bolt.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var setupControls: some View {
        VStack(spacing: 12) {
            if workoutManager.isLoaded {
                Button(action: {
                    workoutManager.loadWorkout(devices: bluetoothManager.peripherals)
                }) {
                    Label("Reload Workout", systemImage: "arrow.down.doc.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            } else {
                Button(action: {
                    workoutManager.loadWorkout(devices: bluetoothManager.peripherals)
                }) {
                    Label("Load Workout", systemImage: "arrow.down.doc.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(workoutManager.hrDeviceAId == nil && workoutManager.powerDeviceAId == nil && workoutManager.hrDeviceBId == nil && workoutManager.powerDeviceBId == nil)
            }
            
            if !workoutManager.exportedFiles.isEmpty {
                SessionSummaryCard(files: workoutManager.exportedFiles, engine: workoutManager.engineA)
            }
        }
        .padding(.top)
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct SessionSummaryCard: View {
    let files: [URL]
    let engine: DataFieldEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SESSION SUMMARY")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.green)
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
            
            let m = engine.calculatedMetrics
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                GridRow {
                    SummaryMetric(label: "AVG POWER", value: "\(Int(round(m.standard.avgPower ?? 0)))W")
                    SummaryMetric(label: "NP", value: "\(Int(round(m.standard.normalizedPower ?? 0)))W")
                }
                GridRow {
                    SummaryMetric(label: "IF", value: String(format: "%.2f", m.standard.intensityFactor ?? 0))
                    SummaryMetric(label: "TSS", value: "\(Int(round(m.standard.tss ?? 0)))")
                }
                GridRow {
                    SummaryMetric(label: "AVG HR", value: "\(Int(round(m.hr.avg ?? 0))) BPM")
                    SummaryMetric(label: "MAX HR", value: "\(Int(round(Double(m.hr.max ?? 0)))) BPM")
                }
            }
            
            ShareLink(items: files) {
                Label("Export Session (.TCX & .FIT)", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SummaryMetric: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
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
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                // Time in Interval
                if let step = workoutManager.currentWorkoutStep {
                    let isFinished = workoutManager.currentStepIndex >= workout.steps.count - 1 && workoutManager.timeInStep >= workout.steps.last?.duration ?? 0
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(isFinished ? "0:00" : formatDuration(step.duration - workoutManager.timeInStep))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("LAP \(max(1, workoutManager.laps.count))")
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
                    
                    // Session Progress in Middle
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            if let start = workoutManager.sessionStartTime {
                                Text("S: \(timeFormatter.string(from: start))")
                            }
                            
                            let remaining = workout.totalDuration - workoutManager.workoutElapsedTime
                            let estimatedEnd = Date().addingTimeInterval(remaining)
                            Text("E: \(timeFormatter.string(from: estimatedEnd))")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)

                        Text("\(formatDuration(workoutManager.workoutElapsedTime)) / \(formatDuration(workout.totalDuration))")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        ProgressView(value: min(1.0, workoutManager.workoutElapsedTime / workout.totalDuration))
                            .tint(.blue)
                            .frame(width: 120)
                            .scaleEffect(x: 1, y: 0.5)
                    }
                    
                    Spacer()
                    
                    // Target Power
                    VStack(alignment: .trailing, spacing: 2) {
                        let scale = workoutManager.workoutDifficultyScale
                        let isFinished = workoutManager.currentStepIndex >= workout.steps.count - 1 && workoutManager.timeInStep >= workout.steps.last?.duration ?? 0
                        
                        if isFinished {
                            Text("0")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("FINISHED")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.secondary)
                        } else {
                            let targetWatts = Int(round(step.targetPowerPercent * scale * SettingsManager.shared.userFTP))
                            Text("\(targetWatts)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(WorkoutZone.forIntensity(step.targetPowerPercent * scale).color)
                            Text("TARGET WATTS")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Legend & Controls
            HStack(spacing: 16) {
                // Mode Selection Dropdown
                Menu {
                    Button(action: { workoutManager.ergModeEnabled = true }) {
                        HStack {
                            Text("ERG Mode")
                            if workoutManager.ergModeEnabled { Image(systemName: "checkmark") }
                        }
                    }
                    .disabled(!workoutManager.canEnableErgMode)
                    
                    Button(action: { workoutManager.ergModeEnabled = false }) {
                        HStack {
                            Text("Resistance Mode")
                            if !workoutManager.ergModeEnabled { Image(systemName: "checkmark") }
                        }
                    }
                    .disabled(!workoutManager.canEnableErgMode)
                } label: {
                    Text(workoutManager.ergModeEnabled ? "ERG" : "RES")
                        .font(.system(size: 12, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(workoutManager.ergModeEnabled ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                // Difficulty Controls
                HStack(spacing: 12) {
                    Button(action: { workoutManager.decreaseDifficulty() }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(Int(round(workoutManager.workoutDifficultyScale * 100)))%")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(width: 60)
                    
                    Button(action: { workoutManager.increaseDifficulty() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundColor(.blue)
                
                if !workoutManager.ergModeEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "plusminus.circle.fill")
                            .foregroundColor(.blue)
                        Slider(value: $workoutManager.resistanceLevel, in: 0...100, step: 1)
                            .frame(maxWidth: 150)
                            .disabled(!workoutManager.canEnableErgMode)
                        Text("\(Int(workoutManager.resistanceLevel))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .frame(width: 30)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Label("Power", systemImage: "bolt.fill").foregroundColor(.yellow)
                    Label("Cadence", systemImage: "bicycle").foregroundColor(.blue)
                    Label("HR", systemImage: "heart.fill").foregroundColor(.red)
                }
                .font(.system(size: 10, weight: .bold))
                
                Picker("Mode", selection: $workoutManager.currentDataFieldMode) {
                    ForEach(WorkoutSessionManager.DataFieldMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 140)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.secondary)
            
            if workoutManager.currentStepIndex < workout.steps.count - 1 {
                let nextStep = workout.steps[workoutManager.currentStepIndex + 1]
                let scale = workoutManager.workoutDifficultyScale
                let nextWatts = Int(round(nextStep.targetPowerPercent * scale * SettingsManager.shared.userFTP))
                HStack {
                    Spacer()
                    Text("Next: \(nextWatts)W (\(Int(nextStep.targetPowerPercent * scale * 100))%) for \(Int(nextStep.duration / 60))m")
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
