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
}
