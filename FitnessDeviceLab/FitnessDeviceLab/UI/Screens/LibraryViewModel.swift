import Foundation
import Observation
import SwiftUI

@Observable
public class LibraryViewModel {
    private let repository = WorkoutRepository.shared
    
    public var searchText = ""
    public var selectedZoneFilter: WorkoutZone? = nil
    public var selectedMetricFilter: StructuredWorkout.WorkoutMetric? = nil
    public var sortOrder: SortOrder = .name
    
    public enum SortOrder: String, CaseIterable, Identifiable {
        case name = "Name"
        case duration = "Duration"
        case intensity = "Intensity"
        public var id: String { rawValue }
    }
    
    public init() {}
    
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
}
