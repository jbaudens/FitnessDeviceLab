import SwiftUI

struct StepInspector: View {
    @Binding var step: WorkoutStep?
    var selectedIDs: Set<UUID> = []
    var onDuplicate: () -> Void
    var onDelete: () -> Void
    var onDuplicateGroup: () -> Void = {}
    var onDeleteGroup: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            if selectedIDs.count > 1 {
                GroupActionsView(
                    count: selectedIDs.count,
                    onDuplicate: onDuplicateGroup,
                    onDelete: onDeleteGroup
                )
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let step = Binding($step) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with Actions
                    HStack {
                        Text("STEP INSPECTOR")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: onDuplicate) {
                                Label("DUPLICATE", systemImage: "plus.square.on.square")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                            
                            Button(action: onDelete) {
                                Label("DELETE", systemImage: "trash")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    Divider()
                    
                    HStack(alignment: .top, spacing: 20) {
                        // Duration Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DURATION")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    TextField("0", value: durationMinutes(step: step), format: .number)
                                        .textFieldStyle(.plain)
                                        .frame(width: 25)
                                        .multilineTextAlignment(.trailing)
                                        .font(.system(.body, design: .monospaced))
                                    Text("m")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(4)
                                
                                HStack(spacing: 4) {
                                    TextField("0", value: durationSeconds(step: step), format: .number)
                                        .textFieldStyle(.plain)
                                        .frame(width: 25)
                                        .multilineTextAlignment(.trailing)
                                        .font(.system(.body, design: .monospaced))
                                    Text("s")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(4)
                            }
                        }
                        
                        // Target Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text(step.wrappedValue.isRamp ? "START TARGET" : "TARGET %")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Slider(value: targetPct(step: step), in: 0.4...1.5, step: 0.01)
                                    .tint(step.wrappedValue.currentZone.color)
                                
                                TextField("%", value: targetPct(step: step), format: .percent.precision(.fractionLength(0)))
                                    .textFieldStyle(.plain)
                                    .frame(width: 45)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    // Ramp Control
                    HStack(alignment: .bottom, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("RAMP")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.secondary)
                            
                            Toggle("", isOn: isRamp(step: step))
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .scaleEffect(0.8)
                                .frame(width: 40, height: 24)
                        }
                        
                        if step.wrappedValue.isRamp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("END TARGET %")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    Slider(value: endTargetPct(step: step), in: 0.4...1.5, step: 0.01)
                                        .tint(step.wrappedValue.currentZone.color)
                                    
                                    TextField("%", value: endTargetPct(step: step), format: .percent.precision(.fractionLength(0)))
                                        .textFieldStyle(.plain)
                                        .frame(width: 45)
                                        .multilineTextAlignment(.trailing)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.primary.opacity(0.05))
                                        .cornerRadius(4)
                                }
                            }
                        } else {
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: step?.id ?? UUID())
        .animation(.spring(), value: selectedIDs.count)
    }
    
    // MARK: - Bindings
    
    private func durationMinutes(step: Binding<WorkoutStep>) -> Binding<Int> {
        Binding(
            get: { Int(step.wrappedValue.duration) / 60 },
            set: { step.wrappedValue.duration = TimeInterval($0 * 60 + (Int(step.wrappedValue.duration) % 60)) }
        )
    }
    
    private func durationSeconds(step: Binding<WorkoutStep>) -> Binding<Int> {
        Binding(
            get: { Int(step.wrappedValue.duration) % 60 },
            set: { step.wrappedValue.duration = TimeInterval((Int(step.wrappedValue.duration) / 60) * 60 + $0) }
        )
    }
    
    private func targetPct(step: Binding<WorkoutStep>) -> Binding<Double> {
        Binding(
            get: { step.wrappedValue.targetPowerPercent ?? 0.0 },
            set: { newValue in
                let wasRamp = step.wrappedValue.isRamp
                step.wrappedValue.targetPowerPercent = newValue
                if !wasRamp {
                    step.wrappedValue.endTargetPowerPercent = newValue
                }
            }
        )
    }
    
    private func endTargetPct(step: Binding<WorkoutStep>) -> Binding<Double> {
        Binding(
            get: { step.wrappedValue.endTargetPowerPercent ?? step.wrappedValue.targetPowerPercent ?? 0.0 },
            set: { step.wrappedValue.endTargetPowerPercent = $0 }
        )
    }
    
    private func isRamp(step: Binding<WorkoutStep>) -> Binding<Bool> {
        Binding(
            get: { step.wrappedValue.isRamp },
            set: { isRamp in
                if !isRamp {
                    step.wrappedValue.endTargetPowerPercent = step.wrappedValue.targetPowerPercent
                } else {
                    if step.wrappedValue.endTargetPowerPercent == step.wrappedValue.targetPowerPercent {
                         step.wrappedValue.endTargetPowerPercent = (step.wrappedValue.targetPowerPercent ?? 0.7) + 0.1
                    }
                }
            }
        )
    }
}

struct GroupActionsView: View {
    let count: Int
    var onDuplicate: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("GROUP ACTIONS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
                Text("\(count) items selected")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Button(action: onDuplicate) {
                Label("DUPLICATE SET", systemImage: "plus.square.on.square.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            Button(role: .destructive, action: onDelete) {
                Label("DELETE GROUP", systemImage: "trash.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        StepInspector(
            step: .constant(WorkoutStep(duration: 300, targetPowerPercent: 0.7)),
            selectedIDs: [UUID()],
            onDuplicate: {},
            onDelete: {},
            onDuplicateGroup: {},
            onDeleteGroup: {}
        )
    }
}
