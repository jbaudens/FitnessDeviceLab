import Foundation
import Observation
import SwiftUI

@Observable
public class LibraryViewModel {
    private let repository: WorkoutRepository
    private let workoutManager: WorkoutSessionManager
    public let settings: SettingsManager
    
    public var searchText = ""
    public var selectedZoneFilter: WorkoutZone? = nil
    public var selectedMetricFilter: StructuredWorkout.WorkoutMetric? = nil
    public var showTestingWorkoutsOnly: Bool = false
    public var sortOrder: SortOrder = .name
    
    public enum SortOrder: String, CaseIterable, Identifiable {
        case name = "Name"
        case duration = "Duration"
        case intensity = "Intensity"
        public var id: String { rawValue }
    }
    
    public init(repository: WorkoutRepository, workoutManager: WorkoutSessionManager, settings: SettingsManager) {
        self.repository = repository
        self.workoutManager = workoutManager
        self.settings = settings
    }
    
    public var filteredWorkouts: [StructuredWorkout] {
        var workouts = repository.allWorkouts
        
        // Search
        if !searchText.isEmpty {
            workouts = workouts.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.description.localizedCaseInsensitiveContains(searchText) 
            }
        }
        
        // Zone Filter
        if let zone = selectedZoneFilter {
            workouts = workouts.filter { $0.primaryZone == zone }
        }
        
        // Metric Filter
        if let metric = selectedMetricFilter {
            workouts = workouts.filter { $0.primaryMetric == metric }
        }
        
        // Testing Filter
        if showTestingWorkoutsOnly {
            workouts = workouts.filter { $0.name.hasPrefix("Test:") }
        } else {
            workouts = workouts.filter { !$0.name.hasPrefix("Test:") }
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
    
    public func selectWorkout(_ workout: StructuredWorkout) {
        workoutManager.selectedWorkout = workout
    }
    
    public func duplicateWorkout(_ workout: StructuredWorkout) {
        let newWorkout = StructuredWorkout(
            id: UUID(),
            name: "\(workout.name) (Copy)",
            description: workout.description,
            steps: workout.steps
        )
        repository.add(newWorkout)
    }
    
    public func deleteWorkout(_ workout: StructuredWorkout) {
        repository.delete(workout)
    }
}
