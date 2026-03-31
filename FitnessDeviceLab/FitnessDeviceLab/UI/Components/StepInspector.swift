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
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let editingStep = localStep {
                VStack(alignment: .leading, spacing: 16) {
                    // Action Header
                    HStack {
                        Text("EDITING STEP")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            actionIconButton(icon: "arrow.left", action: onMoveLeft)
                            actionIconButton(icon: "arrow.right", action: onMoveRight)
                            Divider().frame(height: 16).padding(.horizontal, 4)
                            actionIconButton(icon: "plus.square.on.square", action: onDuplicate)
                            actionIconButton(icon: "trash", color: .red, action: onDelete)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        // Metric Selection
                        HStack {
                            Text("TARGET METRIC")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("Metric", selection: metricBinding) {
                                Label("Power", systemImage: "bolt.fill").tag(StructuredWorkout.WorkoutMetric.power)
                                Label("Heart Rate", systemImage: "heart.fill").tag(StructuredWorkout.WorkoutMetric.heartRate)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                        .padding(.bottom, 4)

                        // Interval Type Selection
                        HStack {
                            Text("INTERVAL TYPE")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("Type", selection: typeBinding) {
                                ForEach(WorkoutStepType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 220)
                        }
                        .padding(.bottom, 4)

                        // Intensity Control
                        let isHR = editingStep.targetHeartRatePercent != nil
                        inspectorSlider(
                            title: editingStep.isRamp ? "START INTENSITY" : "INTENSITY",
                            value: isHR ? targetHRPct : targetPct,
                            range: 0.1...2.5,
                            step: 0.01,
                            color: editingStep.currentZone.color,
                            formatter: { "\(Int(round($0 * 100)))\(isHR ? " HR" : "%")" },
                            trailingView: {
                                if !isHR {
                                    Toggle("RAMP", isOn: isRamp)
                                        .labelsHidden()
                                        .scaleEffect(0.7)
                                        .frame(width: 35)
                                }
                            }
                        )
                        
                        // End Intensity (Ramp only, Power only)
                        if editingStep.isRamp && !isHR {
                            inspectorSlider(
                                title: "END INTENSITY",
                                value: endTargetPct,
                                range: 0.1...2.5,
                                step: 0.01,
                                color: editingStep.currentZone.color,
                                formatter: { "\(Int(round($0 * 100)))%" }
                            )
                        }
                        
                        // Duration Control
                        inspectorSlider(
                            title: "DURATION",
                            value: durationBinding,
                            range: 15...7200,
                            step: 15,
                            color: .blue,
                            formatter: { formatDuration($0) }
                        )
                    }
                }
                .padding(16)
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: step, initial: true) { _, newValue in
            localStep = newValue
        }
        .animation(.spring(response: 0.3), value: step?.id ?? UUID())
        .animation(.spring(response: 0.3), value: selectedIDs.count)
        .animation(.spring(response: 0.3), value: localStep?.isRamp)
    }
    
    // MARK: - Components
    
    private func inspectorSlider<T: View>(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        color: Color,
        formatter: @escaping (Double) -> String,
        @ViewBuilder trailingView: () -> T = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.secondary)
                Spacer()
                trailingView()
            }
            
            HStack(spacing: 12) {
                Slider(value: value, in: range, step: step)
                    .tint(color)
                
                Text(formatter(value.wrappedValue))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .frame(width: 85, alignment: .trailing)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(6)
            }
        }
    }
    
    private func actionIconButton(icon: String, color: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hrs = Int(duration) / 3600
        let mins = (Int(duration) % 3600) / 60
        let secs = Int(duration) % 60
        if hrs > 0 {
            return String(format: "%dh %02dm", hrs, mins)
        } else if mins > 0 {
            return String(format: "%02dm %02ds", mins, secs)
        } else {
            return String(format: "%02ds", secs)
        }
    }
    
    // MARK: - Safe Local Bindings
    
    private var durationBinding: Binding<Double> {
        Binding(
            get: { localStep?.duration ?? 0.0 },
            set: { 
                localStep?.duration = $0
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

    private var targetHRPct: Binding<Double> {
        Binding(
            get: { localStep?.targetHeartRatePercent ?? 0.0 },
            set: { 
                localStep?.targetHeartRatePercent = $0
                syncBack()
            }
        )
    }

    private var metricBinding: Binding<StructuredWorkout.WorkoutMetric> {
        Binding(
            get: { 
                localStep?.targetHeartRatePercent != nil ? .heartRate : .power 
            },
            set: { newMetric in
                if newMetric == .heartRate {
                    // Switch to HR: use current power or default to 0.7
                    let currentVal = localStep?.targetPowerPercent ?? 0.7
                    localStep?.targetHeartRatePercent = currentVal
                    localStep?.targetPowerPercent = nil
                    localStep?.endTargetPowerPercent = nil
                } else {
                    // Switch to Power: use current HR or default to 0.7
                    let currentVal = localStep?.targetHeartRatePercent ?? 0.7
                    localStep?.targetPowerPercent = currentVal
                    localStep?.endTargetPowerPercent = currentVal
                    localStep?.targetHeartRatePercent = nil
                }
                syncBack()
            }
        )
    }

    private var typeBinding: Binding<WorkoutStepType> {
        Binding(
            get: { localStep?.type ?? .work },
            set: { 
                localStep?.type = $0
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
            VStack(alignment: .leading, spacing: 2) {
                Text("GROUP ACTIONS")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
                Text("\(count) selected")
                    .font(.system(size: 12, weight: .bold))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                actionIconButton(icon: "arrow.left", action: onMoveLeft)
                actionIconButton(icon: "arrow.right", action: onMoveRight)
                Divider().frame(height: 16).padding(.horizontal, 4)
                actionIconButton(icon: "plus.square.on.square.fill", action: onDuplicate)
                actionIconButton(icon: "trash.fill", color: .red, action: onDelete)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func actionIconButton(icon: String, color: Color = .blue, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
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
    .padding()
    .background(Color.gray.opacity(0.1))
}
