import Foundation
import Observation
import SwiftUI

@Observable
public class WorkoutRepository {
    public static let shared = WorkoutRepository()
    
    private let storageKey: String
    private let userDefaults: UserDefaults
    private(set) public var allWorkouts: [StructuredWorkout] = []
    
    public var workoutsByZone: [WorkoutZone: [StructuredWorkout]] {
        Dictionary(grouping: allWorkouts) { $0.primaryZone }
    }
    
    private init(storageKey: String = "com.fitnessdevicelab.workouts", userDefaults: UserDefaults = .standard) {
        self.storageKey = storageKey
        self.userDefaults = userDefaults
        loadWorkouts()
    }
    
    // Internal initializer for testing
    internal static func createForTesting(storageKey: String, userDefaults: UserDefaults) -> WorkoutRepository {
        return WorkoutRepository(storageKey: storageKey, userDefaults: userDefaults)
    }
    
    // MARK: - CRUD Operations
    
    public func add(_ workout: StructuredWorkout) {
        allWorkouts.append(workout)
        saveWorkouts()
    }
    
    public func update(_ workout: StructuredWorkout) {
        if let index = allWorkouts.firstIndex(where: { $0.id == workout.id }) {
            allWorkouts[index] = workout
            saveWorkouts()
        }
    }
    
    public func delete(_ workout: StructuredWorkout) {
        allWorkouts.removeAll(where: { $0.id == workout.id })
        saveWorkouts()
    }
    
    public func delete(at offsets: IndexSet) {
        allWorkouts.remove(atOffsets: offsets)
        saveWorkouts()
    }
    
    // MARK: - Persistence
    
    private func loadWorkouts() {
        if let data = userDefaults.data(forKey: storageKey) {
            do {
                let decoded = try JSONDecoder().decode([StructuredWorkout].self, from: data)
                self.allWorkouts = decoded.sorted { $0.name < $1.name }
            } catch {
                seedDefaultWorkouts()
            }
        } else {
            seedDefaultWorkouts()
        }
    }
    
    private func saveWorkouts() {
        do {
            let encoded = try JSONEncoder().encode(allWorkouts)
            userDefaults.set(encoded, forKey: storageKey)
        } catch {
            print("Error encoding workouts: \(error)")
        }
    }
    
    private func seedDefaultWorkouts() {
        // Use the statically defined workouts from Workouts.swift
        self.allWorkouts = DefaultWorkouts.all.sorted { $0.name < $1.name }
        saveWorkouts()
    }
}
