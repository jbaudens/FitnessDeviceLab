import SwiftUI

struct InteractionCockpit: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var workoutManager: WorkoutSessionManager
    var onStop: (() -> Void)? = nil
    
    private var isRegular: Bool { horizontalSizeClass == .regular }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // 1. Mode Selection
                modePicker
                
                Divider().frame(height: 32)
                
                // 2. Incremental Adjustments (Restored +/- 1 and +/- 5/10)
                adjustmentGroup
                
                Spacer()
                
                Divider().frame(height: 32)
                
                // 3. Primary Session Controls (Consistent Circular Style)
                sessionControls
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
        .foregroundColor(.blue)
    }
    
    @ViewBuilder
    private var modePicker: some View {
        if workoutManager.selectedWorkout == nil {
            Picker("Mode", selection: $workoutManager.freeRideControlMode) {
                ForEach(WorkoutSessionManager.FreeRideControlMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        } else {
            Picker("Mode", selection: $workoutManager.ergModeEnabled) {
                Text("RES").tag(false)
                Text("ERG").tag(true)
            }
            .pickerStyle(.segmented)
            .disabled(!workoutManager.canEnableErgMode)
            .frame(width: 120)
        }
    }
    
    @ViewBuilder
    private var adjustmentGroup: some View {
        HStack(spacing: 8) {
            let coarseAmount = (workoutManager.selectedWorkout == nil && workoutManager.freeRideControlMode == .power) ? 10 : 5
            
            // Coarse Down
            Button(action: { workoutManager.adjustManualTarget(amount: -coarseAmount) }) {
                Image(systemName: "minus.square.fill")
                    .font(.title3)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            // Fine Down
            Button(action: { workoutManager.adjustManualTarget(amount: -1) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
            }
            
            // Value
            VStack(spacing: 0) {
                Text(currentValueString)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text(currentLabelString)
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 60)
            
            // Fine Up
            Button(action: { workoutManager.adjustManualTarget(amount: 1) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            
            // Coarse Up
            Button(action: { workoutManager.adjustManualTarget(amount: coarseAmount) }) {
                Image(systemName: "plus.square.fill")
                    .font(.title3)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }
    
    @ViewBuilder
    private var sessionControls: some View {
        HStack(spacing: 16) {
            if !workoutManager.isRecording {
                // Cancel
                Button(action: {
                    workoutManager.isLoaded = false
                    workoutManager.isRecording = false
                }) {
                    circularControl(icon: "xmark", color: .gray)
                }
                
                // Start (The only one with a label for extra clarity)
                Button(action: {
                    workoutManager.startRecording()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("START").font(.system(size: 12, weight: .black))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            } else {
                // Lap
                Button(action: { workoutManager.manualLap() }) {
                    circularControl(icon: "circle.circle.fill", color: .blue)
                }
                .disabled(workoutManager.isPaused)
                
                // Pause/Resume
                Button(action: {
                    if workoutManager.isPaused {
                        workoutManager.resumeWorkout()
                    } else {
                        workoutManager.pauseWorkout()
                    }
                }) {
                    circularControl(
                        icon: workoutManager.isPaused ? "play.fill" : "pause.fill",
                        color: .orange,
                        size: 44
                    )
                }
                
                // Stop
                Button(action: { onStop?() }) {
                    circularControl(icon: "stop.fill", color: .red)
                }
            }
        }
    }
    
    private func circularControl(icon: String, color: Color, size: CGFloat = 36) -> some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(color.gradient)
            .clipShape(Circle())
            .shadow(radius: 2)
    }
    
    private var currentValueString: String {
        if let _ = workoutManager.selectedWorkout {
            return workoutManager.ergModeEnabled ? "\(Int(round(workoutManager.workoutDifficultyScale * 100)))%" : "\(Int(workoutManager.resistanceLevel))%"
        }
        switch workoutManager.freeRideControlMode {
        case .heartRate: return "\(workoutManager.manualTargetHR)"
        case .power: return "\(workoutManager.manualTargetPower)"
        case .resistance: return "\(Int(workoutManager.resistanceLevel))%"
        }
    }
    
    private var currentLabelString: String {
        if let _ = workoutManager.selectedWorkout {
            return workoutManager.ergModeEnabled ? "INTENSITY" : "LEVEL"
        }
        switch workoutManager.freeRideControlMode {
        case .heartRate: return "BPM"
        case .power: return "WATTS"
        case .resistance: return "LEVEL"
        }
    }
}
