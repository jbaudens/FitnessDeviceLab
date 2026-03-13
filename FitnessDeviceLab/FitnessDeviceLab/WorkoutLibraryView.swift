import SwiftUI

struct WorkoutLibraryView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    let repository = WorkoutRepository.shared
    
    @State private var searchText = ""
    @State private var selectedZoneFilter: WorkoutZone? = nil
    @State private var selectedMetricFilter: StructuredWorkout.WorkoutMetric? = nil
    @State private var sortOrder: SortOrder = .name
    
    enum SortOrder: String, CaseIterable, Identifiable {
        case name = "Name"
        case duration = "Duration"
        case intensity = "Intensity"
        var id: String { rawValue }
    }
    
    var filteredWorkouts: [StructuredWorkout] {
        var workouts = repository.allWorkouts
        
        // Search
        if !searchText.isEmpty {
            workouts = workouts.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Zone Filter
        if let zone = selectedZoneFilter {
            workouts = workouts.filter { $0.primaryZone == zone }
        }
        
        // Metric Filter
        if let metric = selectedMetricFilter {
            workouts = workouts.filter { $0.primaryMetric == metric }
        }
        
        // Sort
        switch sortOrder {
        case .name:
            workouts.sort { $0.name < $1.name }
        case .duration:
            workouts.sort { $0.totalDuration < $1.totalDuration }
        case .intensity:
            workouts.sort { $0.intensityFactor > $1.intensityFactor }
        }
        
        return workouts
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters Header
                VStack(alignment: .leading, spacing: 12) {
                    // Zone Badges
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterBadge(name: "All Zones", color: .secondary, isSelected: selectedZoneFilter == nil) {
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
                        .padding(.horizontal)
                    }
                    
                    // Metric Badges (Power / HR)
                    HStack(spacing: 8) {
                        FilterBadge(name: "All Metrics", color: .secondary, isSelected: selectedMetricFilter == nil) {
                            selectedMetricFilter = nil
                        }
                        
                        FilterBadge(name: "Power Only", color: .yellow, isSelected: selectedMetricFilter == .power) {
                            selectedMetricFilter = .power
                        }
                        
                        FilterBadge(name: "HR Only", color: .red, isSelected: selectedMetricFilter == .heartRate) {
                            selectedMetricFilter = .heartRate
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGroupedBackground))
                
                List {
                    if filteredWorkouts.isEmpty {
                        Section {
                            ContentUnavailableView("No Workouts Found", systemImage: "magnifyingglass", description: Text("Try adjusting your filters or search terms."))
                        }
                    } else {
                        ForEach(filteredWorkouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                WorkoutRowView(workout: workout)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu {
                Picker("Sort By", selection: $sortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Text("Sort by \(order.rawValue)").tag(order)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search workouts...")
        }
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
