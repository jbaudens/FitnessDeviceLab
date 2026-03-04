import Foundation

public struct WorkoutRepository {
    public static let shared = WorkoutRepository()
    
    public let allWorkouts: [StructuredWorkout]
    
    public var workoutsByZone: [WorkoutZone: [StructuredWorkout]] {
        Dictionary(grouping: allWorkouts) { $0.primaryZone }
    }
    
    private init() {
        // Use the statically defined workouts from Workouts.swift
        // This ensures they are always available regardless of bundle state
        self.allWorkouts = DefaultWorkouts.all.sorted { $0.name < $1.name }
    }
}
