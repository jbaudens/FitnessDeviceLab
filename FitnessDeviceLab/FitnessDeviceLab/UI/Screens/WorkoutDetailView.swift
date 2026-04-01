import SwiftUI

struct WorkoutDetailView: View {
    let workoutID: UUID
    @Bindable var repository: WorkoutRepository
    let userFTP: Double
    let userLTHR: Double
    let onSelect: (StructuredWorkout) -> Void
    var onEdit: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    
    private var workout: StructuredWorkout? {
        repository.allWorkouts.first(where: { $0.id == workoutID })
    }
    
    var body: some View {
        Group {
            if let workout = workout {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Large Graph
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Workout Profile")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        if workout.isHybrid {
                                            Label("Power", systemImage: "bolt.fill")
                                                .font(.caption)
                                                .fontWeight(.black)
                                                .foregroundColor(.yellow)
                                            
                                            Label("Heart Rate", systemImage: "heart.fill")
                                                .font(.caption)
                                                .fontWeight(.black)
                                                .foregroundColor(.red)
                                        } else {
                                            Label(workout.primaryMetric.rawValue, systemImage: workout.primaryMetric == .power ? "bolt.fill" : "heart.fill")
                                                .font(.caption)
                                                .fontWeight(.black)
                                                .foregroundColor(workout.primaryMetric == .power ? .yellow : .red)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Text("Z\(workout.primaryZone.rawValue)")
                                    .font(.system(size: 14, weight: .black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(workout.primaryZone.color)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                            
                            WorkoutGraphView(workout: workout, userFTP: userFTP, userLTHR: userLTHR)
                                .frame(height: 200)
                                .padding()
                                .background(Color.secondary.opacity(0.05))
                                .cornerRadius(12)
                        }
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack(alignment: .leading) {
                                Text("Duration")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(workout.totalDuration / 60)) min")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Intensity")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.2f", workout.intensityFactor)) IF")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Intervals")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(workout.steps.filter { $0.type == .work }.count)")
                                    .font(.headline)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text(workout.description)
                                .font(.body)
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                onSelect(workout)
                                dismiss()
                            }) {
                                Label("Select Workout", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(workout.primaryZone.color)
                            
                            if let onEdit = onEdit {
                                Button(action: {
                                    onEdit()
                                }) {
                                    Label("Edit Workout", systemImage: "pencil")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.bordered)
                                .tint(.primary)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle(workout.name)
            } else {
                ContentUnavailableView("Workout Not Found", systemImage: "xmark.circle")
            }
        }
    }
}

#Preview {
    let workout = StructuredWorkout(
        name: "Endurance Base",
        description: "A steady ride in Zone 2 to build aerobic capacity and fat metabolism.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.5),
            WorkoutStep(duration: 1800, targetPowerPercent: 0.7),
            WorkoutStep(duration: 600, targetPowerPercent: 0.5)
        ]
    )
    
    NavigationStack {
        WorkoutDetailView(workoutID: workout.id, repository: WorkoutRepository.shared, userFTP: 250, userLTHR: 170, onSelect: { _ in })
    }
}
