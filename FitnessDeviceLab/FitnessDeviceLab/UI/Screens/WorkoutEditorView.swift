import SwiftUI

struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: WorkoutEditorViewModel
    
    var body: some View {
        @Bindable var vm = viewModel
        
        NavigationStack {
            VStack(spacing: 0) {
                // Header (Summary Metrics)
                WorkoutSummaryHeader(
                    duration: vm.totalDuration,
                    tss: vm.tss,
                    intensityFactor: vm.intensityFactor
                )
                .padding()
                .background(Color.secondary.opacity(0.05))
                
                Form {
                    Section(header: Text("Basic Info")) {
                        TextField("Workout Name", text: $vm.name)
                        TextField("Description", text: $vm.description, axis: .vertical)
                            .lineLimit(3...5)
                    }
                    
                    Section(header: Text("Steps")) {
                        if vm.steps.isEmpty {
                            Text("No steps added yet.")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(vm.steps) { step in
                                Text("Step: \(Int(step.duration / 60)) min")
                            }
                        }
                        
                        Button(action: {
                            // TODO: Add step logic in Task 3
                        }) {
                            Label("Add Step", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle(vm.isNewWorkout ? "New Workout" : "Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("SAVE") {
                        vm.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
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
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("TOTAL TIME")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 2) {
                Text(String(format: "%.0f", tss))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("EST. TSS")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", intensityFactor))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
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
