import SwiftUI

struct WorkoutPlayerView: View {
    @Bindable var viewModel: WorkoutPlayerViewModel
    
    var body: some View {
        WorkoutPlayerContentView(viewModel: viewModel)
    }
}

// MARK: - Previews

#Preview("Free Ride") {
    let settings = SettingsManager()
    let locationManager = LocationManager()
    let timer = SessionTimer()
    let errorManager = ErrorManager()
    let recorderA = SessionRecorder(settings: settings)
    let recorderB = SessionRecorder(settings: settings)
    let manager = WorkoutSessionManager(
        settings: settings, 
        locationProvider: locationManager, 
        sessionTimer: timer,
        recorderA: recorderA,
        recorderB: recorderB,
        errorManager: errorManager
    )
    let bluetooth = BluetoothManager(settings: settings, errorManager: errorManager)
    
    let viewModel = WorkoutPlayerViewModel(workoutManager: manager, bluetoothManager: bluetooth, settings: settings)
    
    // Setup some mock data for Free Ride
    let _ = {
        manager.isLoaded = true
        manager.isRecording = true
        timer.resume()
        for _ in 0..<1200 { timer.advanceOneSecond() }
        
        let now = Date()
        for i in 0..<1200 {
            let pt = Trackpoint(
                time: now.addingTimeInterval(Double(i)),
                hr: 130 + Int(sin(Double(i)/30.0) * 10),
                power: 220 + Int(cos(Double(i)/30.0) * 40)
            )
            manager.recorderA.trackpoints.append(pt)
        }
        manager.freeRideControlMode = .power
        manager.manualTargetPower = 220
        return true
    }()
    
    NavigationStack {
        WorkoutPlayerView(viewModel: viewModel)
    }
}

#Preview("Structured Workout") {
    let settings = SettingsManager()
    let locationManager = LocationManager()
    let timer = SessionTimer()
    let errorManager = ErrorManager()
    let recorderA = SessionRecorder(settings: settings)
    let recorderB = SessionRecorder(settings: settings)
    let manager = WorkoutSessionManager(
        settings: settings, 
        locationProvider: locationManager, 
        sessionTimer: timer,
        recorderA: recorderA,
        recorderB: recorderB,
        errorManager: errorManager
    )
    let bluetooth = BluetoothManager(settings: settings, errorManager: errorManager)
    
    let workout = StructuredWorkout(
        name: "Power Pyramids",
        description: "Classic intervals",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.5),
            WorkoutStep(duration: 300, targetPowerPercent: 0.7),
            WorkoutStep(duration: 300, targetPowerPercent: 0.9),
            WorkoutStep(duration: 300, targetPowerPercent: 0.7),
            WorkoutStep(duration: 300, targetPowerPercent: 0.5)
        ]
    )
    
    let viewModel = WorkoutPlayerViewModel(workoutManager: manager, bluetoothManager: bluetooth, settings: settings)
    
    // Setup some mock data for Workout
    let _ = {
        manager.selectedWorkout = workout
        manager.isLoaded = true
        manager.isRecording = true
        timer.resume()
        for _ in 0..<750 { timer.advanceOneSecond() }
        manager.currentStepIndex = 2
        manager.timeInStep = 150
        
        let now = Date()
        for i in 0..<750 {
            let pt = Trackpoint(
                time: now.addingTimeInterval(Double(i)),
                hr: 120 + Int(Double(i)/10.0),
                power: 200 + Int(sin(Double(i)/20.0) * 20)
            )
            manager.recorderA.trackpoints.append(pt)
        }
        return true
    }()
    
    NavigationStack {
        WorkoutPlayerView(viewModel: viewModel)
    }
}

#Preview("Session Summary Card") {
    let settings = SettingsManager()
    let engine = DataFieldEngine(settings: settings)
    let _ = {
        engine.liveStandard.instant = 250
        engine.currentHR = 145
        return true
    }()
    
    SessionSummaryCard(files: [], engine: engine)
        .padding()
}

#Preview("Interaction Cockpit - Free Ride") {
    let settings = SettingsManager()
    let locationManager = LocationManager()
    let timer = SessionTimer()
    let errorManager = ErrorManager()
    let recorderA = SessionRecorder(settings: settings)
    let recorderB = SessionRecorder(settings: settings)
    let manager = WorkoutSessionManager(
        settings: settings, 
        locationProvider: locationManager, 
        sessionTimer: timer,
        recorderA: recorderA,
        recorderB: recorderB,
        errorManager: errorManager
    )
    InteractionCockpit(workoutManager: manager)
        .padding()
}

#Preview("Workout Target Header") {
    let settings = SettingsManager()
    let locationManager = LocationManager()
    let timer = SessionTimer()
    let errorManager = ErrorManager()
    let recorderA = SessionRecorder(settings: settings)
    let recorderB = SessionRecorder(settings: settings)
    let manager = WorkoutSessionManager(
        settings: settings, 
        locationProvider: locationManager, 
        sessionTimer: timer,
        recorderA: recorderA,
        recorderB: recorderB,
        errorManager: errorManager
    )
    let workout = StructuredWorkout(
        name: "Threshold Intervals",
        description: "Hard work",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.95)
        ]
    )
    
    let _ = {
        manager.selectedWorkout = workout
        manager.isRecording = true
        timer.resume()
        for _ in 0..<120 { timer.advanceOneSecond() }
        manager.timeInStep = 120
        return true
    }()
    
    WorkoutTargetHeader(workoutManager: manager, workout: workout)
        .padding()
}

#Preview("Laps History") {
    let settings = SettingsManager()
    let locationManager = LocationManager()
    let timer = SessionTimer()
    let errorManager = ErrorManager()
    let recorderA = SessionRecorder(settings: settings)
    let recorderB = SessionRecorder(settings: settings)
    let manager = WorkoutSessionManager(
        settings: settings, 
        locationProvider: locationManager, 
        sessionTimer: timer,
        recorderA: recorderA,
        recorderB: recorderB,
        errorManager: errorManager
    )
    let _ = {
        for _ in 0..<3 {
            manager.lapManager.startNewLap(type: .work)
        }
        return true
    }()
    
    LapsHistoryView(workoutManager: manager, settings: settings)
}

#Preview("Sensor Set Card") {
    let settings = SettingsManager()
    let recorder = SessionRecorder(settings: settings)
    let peripheral = SimulatedPeripheral(name: "Generic Sensor", settings: settings)
    
    SensorSetCard(
        title: "PRIMARY RECORDER (A)",
        subtitle: "Used for primary display & stats",
        color: .blue,
        recorder: recorder,
        hrSensors: [HeartRateSensor(peripheral: peripheral)!],
        pwrSensors: [PowerSensor(peripheral: peripheral)!],
        cadSensors: []
    )
    .padding()
}

struct WorkoutPlayerContentView: View {
    @Bindable var viewModel: WorkoutPlayerViewModel
    
    var body: some View {
        Group {
            if viewModel.isSummaryState {
                VStack {
                    Spacer()
                    let primaryRecorder = viewModel.workoutManager.recorderA.hasAnySensor ? viewModel.workoutManager.recorderA : viewModel.workoutManager.recorderB
                    SessionSummaryCard(files: viewModel.workoutManager.exportedFiles, engine: primaryRecorder.engine)
                        .padding()
                    
                    if viewModel.workoutManager.recorderA.hasAnySensor && viewModel.workoutManager.recorderB.hasAnySensor {
                        Button {
                            viewModel.showingComparison = true
                        } label: {
                            Label("Compare Sensors", systemImage: "chart.bar.xaxis")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .padding(.horizontal)
                    }
                    
                    Button(role: .destructive) {
                        viewModel.showingDiscardConfirmation = true
                    } label: {
                        Label("Discard Session", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                    .alert("Discard Session?", isPresented: $viewModel.showingDiscardConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Discard", role: .destructive) {
                            viewModel.discardSession()
                        }
                    } message: {
                        Text("This will permanently delete the current session data and return to setup.")
                    }
                    
                    Spacer()
                }
                .navigationTitle("Session Summary")
                .sheet(isPresented: $viewModel.showingComparison) {
                    DualPowerComparisonView(
                        recorderA: viewModel.workoutManager.recorderA,
                        recorderB: viewModel.workoutManager.recorderB
                    )
                }
            } else if viewModel.workoutManager.isSaving {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Saving Session Data...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Please wait while we generate your TCX and FIT files.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Saving...")
            } else if viewModel.isActiveState {
                activeView
            } else {
                setupView
            }
        }
    }
    
    private var activeView: some View {
        VStack(spacing: 0) {
            // Status Dashboard (Top)
            if let workout = viewModel.workoutManager.selectedWorkout {
                WorkoutTargetHeader(workoutManager: viewModel.workoutManager, workout: workout)
                    .padding()
                    .background(Color.secondary.opacity(0.05))
            } else {
                FreeRideHeader(workoutManager: viewModel.workoutManager)
                    .padding()
                    .background(Color.secondary.opacity(0.05))
            }
            
            SensorConnectionStatusBar(
                recorderA: viewModel.workoutManager.recorderA,
                recorderB: viewModel.workoutManager.recorderB,
                trainer: viewModel.workoutManager.trainerController.trainer
            )
            
            AdaptiveWorkoutDashboard(viewModel: viewModel, settings: viewModel.settings)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Fixed Bottom Zone (Cockpit & Controls)
            VStack(spacing: 0) {
                Divider()
                
                // Cockpit Zone (Bottom Interaction)
                InteractionCockpit(workoutManager: viewModel.workoutManager)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                activeControls
            }
            .background(Color.systemBackground)
        }
        .navigationTitle(viewModel.workoutManager.selectedWorkout?.name ?? "Free Ride")
        .inlineNavigationBarTitle()
    }
    
    private var activeControls: some View {
        HStack(spacing: 16) {
            if !viewModel.workoutManager.isRecording {
                Button(action: {
                    viewModel.workoutManager.isLoaded = false
                    viewModel.workoutManager.isRecording = false
                }) {
                    Label("Cancel", systemImage: "xmark.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                
                Button(action: {
                    viewModel.workoutManager.startRecording()
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
                    viewModel.workoutManager.manualLap()
                }) {
                    Label("Lap", systemImage: "circle.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(viewModel.workoutManager.isPaused)
                
                Button(action: {
                    if viewModel.workoutManager.isPaused {
                        viewModel.workoutManager.resumeWorkout()
                    } else {
                        viewModel.workoutManager.pauseWorkout()
                    }
                }) {
                    Label(viewModel.workoutManager.isPaused ? "Resume" : "Pause", systemImage: viewModel.workoutManager.isPaused ? "play.fill" : "pause.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button(action: {
                    viewModel.showingStopConfirmation = true
                }) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .alert("Stop Workout?", isPresented: $viewModel.showingStopConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Stop & Save", role: .destructive) {
                        viewModel.workoutManager.stopWorkout()
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
                if viewModel.availableHRSensors.isEmpty && viewModel.availablePowerSensors.isEmpty {
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
            
            ActivityProfileSelector(
                selectedProfile: $viewModel.workoutManager.activeProfile,
                profiles: ActivityProfile.availableProfiles
            )
            
            if let workout = viewModel.workoutManager.selectedWorkout {
                selectedWorkoutCard(workout: workout)
            }

            if viewModel.workoutManager.isLoaded && !viewModel.workoutManager.isRecording {
                liveDataPreview
            }

            trainerSelectionCard
            
            sensorSelectionSection
            
            setupControls
        }
    }
    
    private var trainerSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CONTROL SOURCE")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.green)
                Text("Device used for ERG and Resistance commands")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Label {
                    Text("Smart Trainer").font(.subheadline)
                } icon: {
                    Image(systemName: "cpu").foregroundColor(.green)
                }
                Spacer()
                Picker("Trainer", selection: $viewModel.controlSource) {
                    Text("Read Only (No Control)").tag(nil as ControllableTrainer?)
                    ForEach(viewModel.availableTrainers, id: \.id) { trainer in
                        Text(trainer.name).tag(trainer as ControllableTrainer?)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var setupHeader: some View {
        HStack {
            Text("Workout Setup")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button("Clear All") {
                viewModel.clearAllSelections()
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
                color: Color.blue,
                recorder: viewModel.recorderA,
                hrSensors: viewModel.availableHRSensors,
                pwrSensors: viewModel.availablePowerSensors,
                cadSensors: viewModel.availableCadenceSensors
            )
            
            SensorSetCard(
                title: "SECONDARY RECORDER (B)",
                subtitle: "Background comparison recording",
                color: Color.purple,
                recorder: viewModel.recorderB,
                hrSensors: viewModel.availableHRSensors,
                pwrSensors: viewModel.availablePowerSensors,
                cadSensors: viewModel.availableCadenceSensors
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
                
                Button(action: { viewModel.workoutManager.selectedWorkout = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(workout.name)
                .font(.headline)
            
            WorkoutGraphView(workout: workout, userFTP: viewModel.settings.userFTP, showAxis: false, scale: viewModel.workoutManager.workoutDifficultyScale)
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
                        Text("\(viewModel.recorderA.hrSource?.heartRate ?? 0)")
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
                        Text("\(viewModel.recorderA.powerSource?.cyclingPower ?? 0)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("W")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if (viewModel.recorderA.powerSource?.cyclingPower ?? 0) > 0 {
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
            if viewModel.workoutManager.isLoaded {
                Button(action: {
                    viewModel.loadWorkout()
                }) {
                    Label(viewModel.workoutManager.selectedWorkout != nil ? "Reload Workout" : "Reset Free Ride", systemImage: "arrow.down.doc.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            } else {
                Button(action: {
                    viewModel.loadWorkout()
                }) {
                    Label(viewModel.workoutManager.selectedWorkout != nil ? "Load Workout" : "Start Free Ride", systemImage: viewModel.workoutManager.selectedWorkout != nil ? "arrow.down.doc.fill" : "play.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(viewModel.recorderA.hrSource == nil && viewModel.recorderA.powerSource == nil && viewModel.recorderB.hrSource == nil && viewModel.recorderB.powerSource == nil)
            }
        }
        .padding(.top)
    }
}

// MARK: - Components

struct FreeRideHeader: View {
    @Bindable var workoutManager: WorkoutSessionManager
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDuration(workoutManager.workoutElapsedTime))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("SESSION TIME")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 2) {
                Text("LAP \(workoutManager.laps.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(formatDuration(workoutManager.laps.last?.duration ?? 0))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if workoutManager.freeRideControlMode == .heartRate {
                    Text("\(workoutManager.manualTargetHR)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                    Text("GOAL BPM")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                } else if workoutManager.freeRideControlMode == .power {
                    Text("\(workoutManager.manualTargetPower)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                    Text("TARGET W")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                } else {
                    Text("\(Int(workoutManager.resistanceLevel))%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                    Text("RESISTANCE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}


