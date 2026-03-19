import SwiftUI

struct WorkoutDetailView: View {
    let workout: StructuredWorkout
    let userFTP: Double
    let onSelect: (StructuredWorkout) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
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
                            
                            HStack {
                                Label(workout.primaryMetric.rawValue, systemImage: workout.primaryMetric == .power ? "bolt.fill" : "heart.fill")
                                    .font(.caption)
                                    .fontWeight(.black)
                                    .foregroundColor(workout.primaryMetric == .power ? .yellow : .red)
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
                    
                    WorkoutGraphView(workout: workout, userFTP: userFTP)
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
                
                Spacer()
                
                Button(action: {
                    onSelect(workout)
                    dismiss()
                }) {
                    Text("Select Workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(workout.primaryZone.color)
            }
            .padding()
        }
        .navigationTitle(workout.name)
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
        WorkoutDetailView(workout: workout, userFTP: 250, onSelect: { _ in })
    }
}
