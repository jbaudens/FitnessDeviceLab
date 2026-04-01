import SwiftUI

struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var viewModel: WorkoutEditorViewModel
    
    var body: some View {
        @Bindable var vm = viewModel
        
        VStack(spacing: 0) {
            // Header (Summary Metrics)
            WorkoutSummaryHeader(
                duration: vm.totalDuration,
                tss: vm.tss,
                intensityFactor: vm.intensityFactor
            )
            .padding()
            .background(Color.secondary.opacity(0.05))
            
            ScrollView {
                VStack(spacing: 16) {
                    // Collapsible Basic Info
                    CollapsibleWorkoutInfo(
                        name: $vm.name,
                        description: $vm.description,
                        isNewWorkout: vm.isNewWorkout,
                        onDelete: {
                            vm.deleteWorkout()
                            dismiss()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Visual Timeline
                    WorkoutTimelineCanvas(
                        steps: $vm.steps,
                        selectedStepID: $vm.selectedStepID,
                        selectedStepIDs: $vm.selectedStepIDs
                    )
                    .frame(height: 180)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // The Horizon Bar (Adaptive Layout)
                    Group {
                        if horizontalSizeClass == .regular {
                            HStack(alignment: .top, spacing: 16) {
                                StepPalette(viewModel: vm)
                                    .frame(width: 300)
                                
                                inspectorSection
                            }
                        } else {
                            VStack(spacing: 16) {
                                StepPalette(viewModel: vm)
                                inspectorSection
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(vm.isNewWorkout ? "New Workout" : "Edit Workout")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("SAVE") {
                    vm.save()
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!vm.canSave)
            }
        }
    }
    
    @ViewBuilder
    private var inspectorSection: some View {
        @Bindable var vm = viewModel
        
        if !vm.selectedStepIDs.isEmpty {
            let firstID = vm.selectedStepIDs.first!
            
            StepInspector(
                step: Binding<WorkoutStep?>(
                    get: { 
                        vm.steps.first(where: { $0.id == firstID && vm.selectedStepIDs.count == 1 })
                    },
                    set: { newValue in
                        if let newValue = newValue,
                           let index = vm.steps.firstIndex(where: { $0.id == firstID }) {
                            vm.steps[index] = newValue
                        }
                    }
                ),
                selectedIDs: vm.selectedStepIDs,
                onDuplicate: { vm.duplicateStep(id: firstID) },
                onDelete: { vm.deleteStep(id: firstID) },
                onMoveLeft: { vm.moveStepsLeft(ids: [firstID]) },
                onMoveRight: { vm.moveStepsRight(ids: [firstID]) },
                onDuplicateGroup: { vm.duplicateSteps(ids: vm.selectedStepIDs) },
                onDeleteGroup: { vm.deleteSteps(ids: vm.selectedStepIDs) },
                onMoveLeftGroup: { vm.moveStepsLeft(ids: vm.selectedStepIDs) },
                onMoveRightGroup: { vm.moveStepsRight(ids: vm.selectedStepIDs) }
            )
        } else {
            VStack {
                Text("Select a step or tap palette to add")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

struct WorkoutSummaryHeader: View {
    let duration: TimeInterval
    let tss: Double
    let intensityFactor: Double
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDuration(duration))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("TOTAL TIME")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 2) {
                Text(String(format: "%.0f", tss))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("EST. TSS")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", intensityFactor))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("IF")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hrs = Int(interval) / 3600
        let mins = (Int(interval) % 3600) / 60
        let secs = Int(interval) % 60
        
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}

#Preview {
    WorkoutEditorView(viewModel: WorkoutEditorViewModel())
}
