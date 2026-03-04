import Foundation

public struct DefaultWorkouts {
    public static let all: [StructuredWorkout] = [
        recovery,
        endurance,
        sweetSpot,
        threshold,
        vo2max,
        sprints
    ]
    
    private static let recovery = StructuredWorkout(
        name: "Active Recovery",
        description: "A very light session to promote blood flow and recovery. Keep the cadence easy.",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .warmup),
            WorkoutStep(duration: 1200, targetPowerPercent: 0.50, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
    
    private static let endurance = StructuredWorkout(
        name: "Endurance Base",
        description: "Aerobic conditioning at a steady Zone 2 intensity. Focus on consistent breathing.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 3600, targetPowerPercent: 0.65, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let sweetSpot = StructuredWorkout(
        name: "Sweet Spot Tempo",
        description: "High-level aerobic work just below threshold. Improves muscular endurance.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 720, targetPowerPercent: 0.88, type: .work),
            WorkoutStep(duration: 240, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 720, targetPowerPercent: 0.88, type: .work),
            WorkoutStep(duration: 240, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 720, targetPowerPercent: 0.88, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let threshold = StructuredWorkout(
        name: "Threshold Intervals",
        description: "The gold standard for increasing your sustainable power output.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 1200, targetPowerPercent: 1.00, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 1200, targetPowerPercent: 1.00, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let vo2max = StructuredWorkout(
        name: "VO2 Max Boost",
        description: "High-intensity intervals to improve your maximum aerobic capacity.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 180, targetPowerPercent: 1.20, type: .work),
            WorkoutStep(duration: 180, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 180, targetPowerPercent: 1.20, type: .work),
            WorkoutStep(duration: 180, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 180, targetPowerPercent: 1.20, type: .work),
            WorkoutStep(duration: 180, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 180, targetPowerPercent: 1.20, type: .work),
            WorkoutStep(duration: 180, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 180, targetPowerPercent: 1.20, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let sprints = StructuredWorkout(
        name: "Anaerobic Sprints",
        description: "Short, maximal efforts to build raw power and neuromuscular speed.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 30, targetPowerPercent: 1.50, type: .work),
            WorkoutStep(duration: 270, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 30, targetPowerPercent: 1.50, type: .work),
            WorkoutStep(duration: 270, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 30, targetPowerPercent: 1.50, type: .work),
            WorkoutStep(duration: 270, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 30, targetPowerPercent: 1.50, type: .work),
            WorkoutStep(duration: 270, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 30, targetPowerPercent: 1.50, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
}
