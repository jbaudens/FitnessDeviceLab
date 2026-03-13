import Foundation

public struct DefaultWorkouts {
    public static let all: [StructuredWorkout] = [
        dynamicWarmup,
        recovery,
        endurance,
        gabriel,
        sweetSpot,
        threshold,
        blackcapMinus1,
        vo2max,
        sprints,
        hrTest,
        antelopePlus2,
        hrQuickTest,
        powerQuickTest
    ]
    
    private static let hrQuickTest = StructuredWorkout(
        name: "HR Quick Test",
        description: "Just to test things work.",
        steps: [
            WorkoutStep(duration: 60, targetHeartRatePercent: 0.70, type: .warmup),
            WorkoutStep(duration: 60, targetHeartRatePercent: 0.73, type: .warmup),
            WorkoutStep(duration: 60, targetHeartRatePercent: 0.76, type: .warmup),
            WorkoutStep(duration: 60, targetHeartRatePercent: 0.78, type: .warmup),
            WorkoutStep(duration: 60, targetHeartRatePercent: 0.80, type: .warmup),
        ]
    )
    
    private static let powerQuickTest = StructuredWorkout(
        name: "Power Quick Test",
        description: "Just to test things work.",
        steps: [
            WorkoutStep(duration: 60, targetPowerPercent: 0.40, type: .warmup),
            WorkoutStep(duration: 60, targetPowerPercent: 0.45, type: .warmup),
            WorkoutStep(duration: 60, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 60, targetPowerPercent: 0.55, type: .warmup),
            WorkoutStep(duration: 60, targetPowerPercent: 0.60, type: .warmup),
        ]
    )
    
    private static let hrTest = StructuredWorkout(
        name: "HR Target Test",
        description: "A workout focused on maintaining specific heart rate targets. The trainer will adjust power to hit the HR goals.",
        steps: [
            WorkoutStep(duration: 300, targetHeartRatePercent: 0.70, type: .warmup),
            WorkoutStep(duration: 600, targetHeartRatePercent: 0.85, type: .work), // 85% LTHR
            WorkoutStep(duration: 300, targetHeartRatePercent: 0.70, type: .cooldown)
        ]
    )
    
    private static let dynamicWarmup = StructuredWorkout(
        name: "Dynamic Warmup",
        description: "A comprehensive warmup with progressive ramps and intensity spikes to prepare for hard efforts.",
        steps: {
            var steps: [WorkoutStep] = []
            
            // Phase 1: 10 min ramping from 40% to 60%
            steps.append(WorkoutStep(duration: 600, targetPowerPercent: 0.40, endTargetPowerPercent: 0.60, type: .warmup))
            
            // Phase 2: 5 min alternating between 65% and 80% every 30s
            for _ in 0..<5 {
                steps.append(WorkoutStep(duration: 30, targetPowerPercent: 0.65, type: .warmup))
                steps.append(WorkoutStep(duration: 30, targetPowerPercent: 0.80, type: .warmup))
            }
            
            // Phase 3: 4 min alternating between 60% and 95% (30s intervals)
            for _ in 0..<4 {
                steps.append(WorkoutStep(duration: 30, targetPowerPercent: 0.60, type: .warmup))
                steps.append(WorkoutStep(duration: 30, targetPowerPercent: 0.95, type: .warmup))
            }
            
            return steps
        }()
    )
    
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
    
    private static let gabriel = StructuredWorkout(
        name: "Gabriel",
        description: "120 minutes of aerobic endurance training. This workout aims to build your aerobic base and improve fat metabolism through long, steady-state intervals in Zone 2.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 5940, targetPowerPercent: 0.60, type: .work),
            WorkoutStep(duration: 360, targetPowerPercent: 0.50, type: .cooldown)
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
    
    private static let blackcapMinus1 = StructuredWorkout(
        name: "Blackcap -1",
        description: "3*9min Over-Unders.",
        steps: [
            WorkoutStep(duration: 720, targetPowerPercent: 0.50, endTargetPowerPercent: 0.95, type: .warmup),
            WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 360, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 360, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.10, type: .work),
            WorkoutStep(duration: 240, targetPowerPercent: 0.40, type: .cooldown)
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
    
    
    private static let antelopePlus2 = StructuredWorkout(
        name: "Antelope +2",
        description: "SweetSpot 5*10min 94% FTP",
        steps: [
            WorkoutStep(duration: 180, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 120, targetPowerPercent: 0.65, type: .warmup),
            WorkoutStep(duration: 120, targetPowerPercent: 0.80, type: .warmup),
            WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .warmup),
            WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 600, targetPowerPercent: 0.94, type: .work),
            WorkoutStep(duration: 360, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 600, targetPowerPercent: 0.94, type: .work),
            WorkoutStep(duration: 360, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 600, targetPowerPercent: 0.94, type: .work),
            WorkoutStep(duration: 360, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 600, targetPowerPercent: 0.94, type: .work),
            WorkoutStep(duration: 360, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 600, targetPowerPercent: 0.94, type: .work),
            WorkoutStep(duration: 120, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
}
