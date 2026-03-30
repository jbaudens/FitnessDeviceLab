import SwiftUI

struct InteractionCockpit: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var workoutManager: WorkoutSessionManager
    
    private var isRegular: Bool { horizontalSizeClass == .regular }
    
    var body: some View {
        VStack(spacing: 8) {
            if workoutManager.selectedWorkout == nil {
                // Free Ride Controls
                VStack(spacing: 8) {
                    Picker("Mode", selection: $workoutManager.freeRideControlMode) {
                        ForEach(WorkoutSessionManager.FreeRideControlMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .scaleEffect(isRegular ? 1.0 : 1.0)
                    
                    adjustmentRow(
                        value: currentValueString,
                        label: currentLabelString,
                        coarseAmount: workoutManager.freeRideControlMode == .power ? 10 : 5
                    )
                }
            } else {
                // Structured Workout Controls
                VStack(spacing: 8) {
                    Picker("Mode", selection: $workoutManager.ergModeEnabled) {
                        Text("Resistance").tag(false)
                        Text("ERG Mode").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .disabled(!workoutManager.canEnableErgMode)
                    .scaleEffect(isRegular ? 1.0 : 1.0)
                    
                    adjustmentRow(
                        value: workoutManager.ergModeEnabled ? "\(Int(round(workoutManager.workoutDifficultyScale * 100)))%" : "\(Int(workoutManager.resistanceLevel))%",
                        label: workoutManager.ergModeEnabled ? "INTENSITY" : "LEVEL",
                        coarseAmount: 5
                    )
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
        .foregroundColor(.blue)
    }
    
    @ViewBuilder
    private func adjustmentRow(value: String, label: String, coarseAmount: Int) -> some View {
        let buttonSize: CGFloat = isRegular ? 60 : 60
        let fineIconSize: CGFloat = isRegular ? 44 : 44
        let coarseIconSize: CGFloat = isRegular ? 24 : 24
        
        HStack(spacing: 0) {
            // Coarse Decrease (Subdued & Shielded)
            Button(action: { workoutManager.adjustManualTarget(amount: -coarseAmount) }) {
                VStack(spacing: 2) {
                    Image(systemName: "minus.square.fill")
                        .font(.system(size: coarseIconSize))
                    Text("-\(coarseAmount)")
                        .font(.system(size: 8, weight: .black))
                }
                .foregroundColor(.secondary.opacity(0.6))
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("coarse_decrease")
            
            Spacer().frame(width: 12) // Safety Gutter
            
            // Fine Decrease (Prominent & Central)
            Button(action: { workoutManager.adjustManualTarget(amount: -1) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: fineIconSize))
                    .foregroundColor(.blue)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("fine_decrease")
            
            Spacer()
            
            // Center Value Hero
            VStack(spacing: 0) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 80)
            
            Spacer()
            
            // Fine Increase (Prominent & Central)
            Button(action: { workoutManager.adjustManualTarget(amount: 1) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: fineIconSize))
                    .foregroundColor(.blue)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("fine_increase")
            
            Spacer().frame(width: 12) // Safety Gutter
            
            // Coarse Increase (Subdued & Shielded)
            Button(action: { workoutManager.adjustManualTarget(amount: coarseAmount) }) {
                VStack(spacing: 2) {
                    Image(systemName: "plus.square.fill")
                        .font(.system(size: coarseIconSize))
                    Text("+\(coarseAmount)")
                        .font(.system(size: 8, weight: .black))
                }
                .foregroundColor(.secondary.opacity(0.6))
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("coarse_increase")
        }
        .padding(.horizontal, 4)
    }
    
    private var currentValueString: String {
        switch workoutManager.freeRideControlMode {
        case .heartRate: return "\(workoutManager.manualTargetHR)"
        case .power: return "\(workoutManager.manualTargetPower)"
        case .resistance: return "\(Int(workoutManager.resistanceLevel))%"
        }
    }
    
    private var currentLabelString: String {
        switch workoutManager.freeRideControlMode {
        case .heartRate: return "BPM"
        case .power: return "WATTS"
        case .resistance: return "LEVEL"
        }
    }
}
