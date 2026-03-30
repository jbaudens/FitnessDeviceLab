import XCTest
@testable import FitnessDeviceLab

final class WorkoutRepositoryTests: XCTestCase {
    var repository: WorkoutRepository!
    var testStorageKey: String!
    let testDefaults = UserDefaults.standard
    
    override func setUp() {
        super.setUp()
        testStorageKey = "com.fitnessdevicelab.workouts.test.\(UUID().uuidString)"
        repository = WorkoutRepository.createForTesting(storageKey: testStorageKey, userDefaults: testDefaults)
    }
    
    override func tearDown() {
        testDefaults.removeObject(forKey: testStorageKey)
        super.tearDown()
    }
    
    func testSeedingOnFirstRun() {
        XCTAssertFalse(repository.allWorkouts.isEmpty)
        XCTAssertEqual(repository.allWorkouts.count, DefaultWorkouts.all.count)
    }
    
    func testCRUDOperations() {
        let originalCount = repository.allWorkouts.count
        let newWorkout = StructuredWorkout(
            name: "Test New Workout", 
            description: "Test Description", 
            steps: [WorkoutStep(duration: 60, targetPowerPercent: 0.5, type: .work)]
        )
        
        repository.add(newWorkout)
        XCTAssertEqual(repository.allWorkouts.count, originalCount + 1)
        
        let updatedWorkout = StructuredWorkout(
            id: newWorkout.id, 
            name: "Updated Name", 
            description: "Updated Description", 
            steps: newWorkout.steps
        )
        repository.update(updatedWorkout)
        XCTAssertEqual(repository.allWorkouts.first(where: { $0.id == newWorkout.id })?.name, "Updated Name")
        
        repository.delete(newWorkout)
        XCTAssertEqual(repository.allWorkouts.count, originalCount)
    }
    
    func testPersistence() {
        let uniqueKey = "test.persistence.\(UUID().uuidString)"
        let workout = StructuredWorkout(
            name: "Isolated Workout", 
            description: "Isolated", 
            steps: [WorkoutStep(duration: 60, targetPowerPercent: 0.5, type: .work)]
        )
        
        let repo1 = WorkoutRepository.createForTesting(storageKey: uniqueKey, userDefaults: testDefaults)
        repo1.add(workout)
        
        let repo2 = WorkoutRepository.createForTesting(storageKey: uniqueKey, userDefaults: testDefaults)
        XCTAssertTrue(repo2.allWorkouts.contains(where: { $0.name == "Isolated Workout" }))
        
        testDefaults.removeObject(forKey: uniqueKey)
    }
}
