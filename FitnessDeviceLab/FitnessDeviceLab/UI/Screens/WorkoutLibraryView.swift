import SwiftUI

struct WorkoutLibraryView: View {
    @State private var viewModel: LibraryViewModel
    
    init(repository: WorkoutRepository, workoutManager: WorkoutSessionManager, settings: SettingsManager) {
        _viewModel = State(initialValue: LibraryViewModel(repository: repository, workoutManager: workoutManager, settings: settings))
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            VStack(spacing: 0) {
                // Filters Header
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
                    
                    // Metric Badges (Power / HR)
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
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color.secondary.opacity(0.05))
                
                List {
                    if vm.filteredWorkouts.isEmpty {
                        Section {
                            ContentUnavailableView("No Workouts Found", systemImage: "magnifyingglass", description: Text("Try adjusting your filters or search terms."))
                        }
                    } else {
                        ForEach(vm.filteredWorkouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(
                                workout: workout,
                                userFTP: vm.settings.userFTP,
                                onSelect: { selected in
                                    vm.selectWorkout(selected)
                                }
                            )) {
                                WorkoutRowView(workout: workout, userFTP: vm.settings.userFTP)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout Library")
            .searchable(text: $vm.searchText, prompt: "Search workouts...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Sort By", selection: $vm.sortOrder) {
                            ForEach(LibraryViewModel.SortOrder.allCases) { order in
                                Text("Sort by \(order.rawValue)").tag(order)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
}
