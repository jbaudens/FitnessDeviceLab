import SwiftUI

struct WorkoutLibraryView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    let repository = WorkoutRepository.shared
    
    @State private var selectedZoneFilter: WorkoutZone? = nil
    
    var body: some View {
        List {
            // Zone Filter Picker
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterBadge(name: "All", color: .secondary, isSelected: selectedZoneFilter == nil) {
                            selectedZoneFilter = nil
                        }
                        
                        ForEach(WorkoutZone.allCases) { zone in
                            FilterBadge(
                                name: "Z\(zone.rawValue)",
                                color: zone.color,
                                isSelected: selectedZoneFilter == zone
                            ) {
                                selectedZoneFilter = zone
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Filter by Zone")
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            // Workouts Grouped by Zone
            let groupedWorkouts = repository.workoutsByZone
            let sortedZones = WorkoutZone.allCases.filter { zone in
                if let filter = selectedZoneFilter {
                    return zone == filter
                }
                return groupedWorkouts[zone] != nil
            }
            
            ForEach(sortedZones) { zone in
                if let workouts = groupedWorkouts[zone], !workouts.isEmpty {
                    Section(header: Text(zone.name.uppercased()).foregroundColor(zone.color).fontWeight(.bold)) {
                        ForEach(workouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                WorkoutRowView(workout: workout)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Library")
    }
}

struct FilterBadge: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.1))
                .foregroundColor(isSelected ? .white : color)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutDetailView: View {
    let workout: StructuredWorkout
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Large Graph
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Workout Profile")
                        Spacer()
                        Text("Z\(workout.primaryZone.rawValue)")
                            .font(.system(size: 14, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(workout.primaryZone.color)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    
                    WorkoutGraphView(workout: workout)
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
                        Text("\(String(format: "%.2f", workout.averageIntensity)) IF")
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
                    workoutManager.selectedWorkout = workout
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
