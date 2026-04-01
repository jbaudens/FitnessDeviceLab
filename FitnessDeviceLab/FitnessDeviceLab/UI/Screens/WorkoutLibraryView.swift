import SwiftUI

struct WorkoutLibraryView: View {
    @State private var viewModel: LibraryViewModel
    @State private var workoutToDelete: StructuredWorkout? = nil
    let navigationManager: NavigationManager
    
    init(repository: WorkoutRepository, workoutManager: WorkoutSessionManager, settings: SettingsManager, navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        _viewModel = State(initialValue: LibraryViewModel(repository: repository, workoutManager: workoutManager, settings: settings, navigationManager: navigationManager))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        VStack(spacing: 0) {
            // Filters & Actions Header
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    // Zone Badges
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterBadge(name: "All Zones", color: .secondary, isSelected: vm.selectedZoneFilter == nil) {
                                vm.selectedZoneFilter = nil
                            }
                            
                            ForEach(WorkoutZone.allCases) { zone in
                                FilterBadge(
                                    name: "Z\(zone.rawValue)",
                                    color: zone.color,
                                    isSelected: vm.selectedZoneFilter == zone
                                ) {
                                    vm.selectedZoneFilter = zone
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Metric Badges (Power / HR / Hybrid)
                    HStack(spacing: 8) {
                        FilterBadge(name: "All Metrics", color: .secondary, isSelected: vm.selectedMetricFilter == nil) {
                            vm.selectedMetricFilter = nil
                        }
                        
                        FilterBadge(name: "Power Only", color: .yellow, isSelected: vm.selectedMetricFilter == .power) {
                            vm.selectedMetricFilter = .power
                        }
                        
                        FilterBadge(name: "HR Only", color: .red, isSelected: vm.selectedMetricFilter == .heartRate) {
                            vm.selectedMetricFilter = .heartRate
                        }
                        
                        FilterBadge(name: "Hybrid", color: .purple, isSelected: vm.selectedMetricFilter == .hybrid) {
                            vm.selectedMetricFilter = .hybrid
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Actions: Create & Sort
                HStack(spacing: 12) {
                    Button(action: {
                        navigationManager.navigateToWorkoutEditor()
                    }) {
                        Label("Create Workout", systemImage: "plus.square.fill")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Menu {
                        Section("Order") {
                            Button {
                                vm.sortAscending = true
                            } label: {
                                Label("Ascending", systemImage: vm.sortAscending ? "checkmark" : "")
                            }
                            
                            Button {
                                vm.sortAscending = false
                            } label: {
                                Label("Descending", systemImage: !vm.sortAscending ? "checkmark" : "")
                            }
                        }
                        
                        Section("Sort By") {
                            ForEach(LibraryViewModel.SortOrder.allCases) { order in
                                Button {
                                    vm.sortOrder = order
                                } label: {
                                    HStack {
                                        Text(order.rawValue)
                                        if vm.sortOrder == order {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Sort: \(vm.sortOrder.rawValue)")
                                .font(.subheadline.bold())
                            Image(systemName: vm.sortAscending ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .background(Color.secondary.opacity(0.05))
            
            List {
                if vm.filteredWorkouts.isEmpty {
                    Section {
                        ContentUnavailableView("No Workouts Found", systemImage: "magnifyingglass", description: Text("Try adjusting your filters or search terms."))
                    }
                } else {
                    let grouped = Dictionary(grouping: vm.filteredWorkouts) { $0.primaryZone }
                    let sortedZones = WorkoutZone.allCases.filter { grouped[$0] != nil }
                    
                    ForEach(sortedZones) { zone in
                        Section(header: Text("Zone \(zone.rawValue) - \(zone.name)")) {
                            ForEach(grouped[zone] ?? []) { workout in
                                Button {
                                    navigationManager.navigateToWorkoutDetail(workout)
                                } label: {
                                    WorkoutRowView(workout: workout, userFTP: vm.settings.userFTP, userLTHR: Double(vm.settings.userLTHR))
                                }
                                .foregroundColor(.primary)
                                .contextMenu {
                                    Button {
                                        navigationManager.navigateToWorkoutEditor(workout)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button {
                                        vm.duplicateWorkout(workout)
                                    } label: {
                                        Label("Duplicate", systemImage: "plus.square.on.square")
                                    }
                                    
                                    Button(role: .destructive) {
                                        workoutToDelete = workout
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .onDelete { offsets in
                                if let items = grouped[zone] {
                                    offsets.forEach { index in
                                        vm.deleteWorkout(items[index])
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Workout Library")
        .searchable(text: $vm.searchText, prompt: "Search workouts...")
        .confirmationDialog(
            "Delete Workout",
            isPresented: Binding(
                get: { workoutToDelete != nil },
                set: { if !$0 { workoutToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: workoutToDelete
        ) { workout in
            Button("Delete \"\(workout.name)\"", role: .destructive) {
                vm.deleteWorkout(workout)
                workoutToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
        } message: { workout in
            Text("Are you sure you want to permanently delete this workout?")
        }
    }
}

#Preview {
    let settings = SettingsManager()
    let locationManager = LocationManager()
    let timer = SessionTimer()
    let errorManager = ErrorManager()
    let recorderA = SessionRecorder(settings: settings)
    let recorderB = SessionRecorder(settings: settings)
    let manager = WorkoutSessionManager(
        settings: settings, 
        locationProvider: locationManager, 
        sessionTimer: timer,
        recorderA: recorderA,
        recorderB: recorderB,
        errorManager: errorManager
    )
    
    let navigationManager = NavigationManager()
    
    WorkoutLibraryView(
        repository: WorkoutRepository.shared,
        workoutManager: manager,
        settings: settings,
        navigationManager: navigationManager
    )
}
