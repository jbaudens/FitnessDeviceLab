import SwiftUI

struct StepInspector: View {
    @Binding var step: WorkoutStep?
    var selectedIDs: Set<UUID> = []
    var onDuplicate: () -> Void
    var onDelete: () -> Void
    var onMoveLeft: () -> Void = {}
    var onMoveRight: () -> Void = {}
    var onDuplicateGroup: () -> Void = {}
    var onDeleteGroup: () -> Void = {}
    var onMoveLeftGroup: () -> Void = {}
    var onMoveRightGroup: () -> Void = {}
    
    // Local state to prevent crashes during rapid deletions/updates
    @State private var localStep: WorkoutStep?
    
    var body: some View {
        VStack(spacing: 0) {
            if selectedIDs.count > 1 {
                GroupActionsView(
                    count: selectedIDs.count,
                    onDuplicate: onDuplicateGroup,
                    onDelete: onDeleteGroup,
                    onMoveLeft: onMoveLeftGroup,
                    onMoveRight: onMoveRightGroup
                )
                .padding(16)
                .background(Color.secondarySystemGroupedBackground)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let editingStep = localStep {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with Actions
                    HStack {
                        Text("STEP INSPECTOR")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Button(action: onMoveLeft) {
                                    Image(systemName: "arrow.left")
                                }
                                Button(action: onMoveRight) {
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                            
                            Divider().frame(height: 12)
                            
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
                                durationField(value: durationMinutes, label: "m")
                                durationField(value: durationSeconds, label: "s")
                            }
                        }
                        
                        // Target Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text(editingStep.isRamp ? "START TARGET" : "TARGET %")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Slider(value: targetPct, in: 0.1...2.5, step: 0.01)
                                    .tint(editingStep.currentZone.color)
                                
                                TextField("%", value: targetPct, format: .percent.precision(.fractionLength(0)))
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
                            
                            Toggle("", isOn: isRamp)
                                .toggleStyle(.switch)
                                .labelsHidden()
                                .scaleEffect(0.8)
                                .frame(width: 40, height: 24)
                        }
                        
                        if editingStep.isRamp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("END TARGET %")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    Slider(value: endTargetPct, in: 0.1...2.5, step: 0.01)
                                        .tint(editingStep.currentZone.color)
                                    
                                    TextField("%", value: endTargetPct, format: .percent.precision(.fractionLength(0)))
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
                .background(Color.secondarySystemGroupedBackground)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: step, initial: true) { _, newValue in
            localStep = newValue
        }
        .animation(.spring(), value: step?.id ?? UUID())
        .animation(.spring(), value: selectedIDs.count)
    }
    
    private func durationField(value: Binding<Int>, label: String) -> some View {
        HStack(spacing: 4) {
            TextField("0", value: value, format: .number)
                .textFieldStyle(.plain)
                .frame(width: 25)
                .multilineTextAlignment(.trailing)
                .font(.system(.body, design: .monospaced))
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(4)
    }
    
    // MARK: - Safe Local Bindings
    
    private var durationMinutes: Binding<Int> {
        Binding(
            get: { Int(localStep?.duration ?? 0) / 60 },
            set: { 
                localStep?.duration = TimeInterval($0 * 60 + (Int(localStep?.duration ?? 0) % 60))
                syncBack()
            }
        )
    }
    
    private var durationSeconds: Binding<Int> {
        Binding(
            get: { Int(localStep?.duration ?? 0) % 60 },
            set: { 
                localStep?.duration = TimeInterval((Int(localStep?.duration ?? 0) / 60) * 60 + $0)
                syncBack()
            }
        )
    }
    
    private var targetPct: Binding<Double> {
        Binding(
            get: { localStep?.targetPowerPercent ?? 0.0 },
            set: { newValue in
                let wasRamp = localStep?.isRamp ?? false
                localStep?.targetPowerPercent = newValue
                if !wasRamp {
                    localStep?.endTargetPowerPercent = newValue
                }
                syncBack()
            }
        )
    }
    
    private var endTargetPct: Binding<Double> {
        Binding(
            get: { localStep?.endTargetPowerPercent ?? localStep?.targetPowerPercent ?? 0.0 },
            set: { 
                localStep?.endTargetPowerPercent = $0
                syncBack()
            }
        )
    }
    
    private var isRamp: Binding<Bool> {
        Binding(
            get: { localStep?.isRamp ?? false },
            set: { isRamp in
                if !isRamp {
                    localStep?.endTargetPowerPercent = localStep?.targetPowerPercent
                } else {
                    if localStep?.endTargetPowerPercent == localStep?.targetPowerPercent {
                         localStep?.endTargetPowerPercent = (localStep?.targetPowerPercent ?? 0.7) + 0.1
                    }
                }
                syncBack()
            }
        )
    }
    
    private func syncBack() {
        if let local = localStep {
            step = local
        }
    }
}

struct GroupActionsView: View {
    let count: Int
    var onDuplicate: () -> Void
    var onDelete: () -> Void
    var onMoveLeft: () -> Void = {}
    var onMoveRight: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("GROUP ACTIONS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
                Text("\(count) items selected")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onMoveLeft) {
                    Image(systemName: "arrow.left")
                }
                Button(action: onMoveRight) {
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button(action: onDuplicate) {
                Image(systemName: "plus.square.on.square.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash.fill")
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
