import Foundation

public struct DefaultWorkouts {
    public static let all: [StructuredWorkout] = [
        // Test Workouts
        testIntervalDetection,
        test5min,
        test15min,
        test30min,
        
        // Zone 1: Active Recovery
        activeRecovery30,
        activeRecovery60,
        activeRecovery90,
        
        // Zone 2: Endurance
        enduranceLow45,
        enduranceMid90,
        enduranceHigh2h,
        enduranceMid3h,
        enduranceMid5h,
        
        // Zone 3: Tempo
        tempo2x20,
        tempo3x15,
        
        // Zone 4: Threshold & Sweet Spot
        sweetSpot3x12,
        sweetSpot2x20,
        thresholdOverUnder3x9,
        threshold2x20,
        
        // Zone 5: VO2 Max
        vo2max4x4,
        vo2max4x5,
        intervals30_30,
        intervals40_20,
        
        // Zone 6: Anaerobic
        anaerobicSprints,
        anaerobicPower30_30,
        
        // Zone 7: Sprints
        neuromuscularMaxSprints,
        
        // Legacy/Existing
            dynamicWarmup,
        gabriel,
        antelopePlus2,
        hrTest
    ]
    
    // MARK: - Test Workouts
    
    private static let testIntervalDetection = StructuredWorkout(
        name: "Test: Interval Detection",
        description: "Short workout with sharp power changes to test the interval detection algorithm.",
        steps: [
            WorkoutStep(duration: 120, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 30, targetPowerPercent: 1.20, type: .work),
            WorkoutStep(duration: 30, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 30, targetPowerPercent: 1.50, type: .work),
            WorkoutStep(duration: 30, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 30, targetPowerPercent: 1.80, type: .work),
            WorkoutStep(duration: 120, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
    
    private static let test5min = StructuredWorkout(
        name: "Test: 5 Min Rapid",
        description: "Quick 5 min test with 1 min steps.",
        steps: [
            WorkoutStep(duration: 60, targetPowerPercent: 0.40, type: .warmup),
            WorkoutStep(duration: 60, targetPowerPercent: 0.60, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 0.80, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 1.00, type: .work),
            WorkoutStep(duration: 60, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
    
    private static let test15min = StructuredWorkout(
        name: "Test: 15 Min Power",
        description: "15 min power validation test.",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 600, targetPowerPercent: 0.85, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
    
    private static let test30min = StructuredWorkout(
        name: "Test: 30 Min Aerobic",
        description: "30 min aerobic validation test.",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 1200, targetPowerPercent: 0.70, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
    
    // MARK: - Zone 1: Active Recovery (50% FTP)
    
    private static let activeRecovery30 = StructuredWorkout(
        name: "Recovery: 30m Spin",
        description: "Light 30 min recovery spin at 50% FTP.",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .warmup),
            WorkoutStep(duration: 1200, targetPowerPercent: 0.50, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
    
    private static let activeRecovery60 = StructuredWorkout(
        name: "Recovery: 60m Spin",
        description: "Light 60 min recovery spin at 50% FTP.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.40, type: .warmup),
            WorkoutStep(duration: 2400, targetPowerPercent: 0.50, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
    
    private static let activeRecovery90 = StructuredWorkout(
        name: "Recovery: 90m Spin",
        description: "Light 90 min recovery spin at 50% FTP.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.40, type: .warmup),
            WorkoutStep(duration: 4200, targetPowerPercent: 0.50, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.40, type: .cooldown)
        ]
    )
    
    // MARK: - Zone 2: Endurance (55-75% FTP)
    
    private static let enduranceLow45 = StructuredWorkout(
        name: "Endurance: Low (45m)",
        description: "45 minutes of low-intensity endurance at 55% FTP.",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.45, type: .warmup),
            WorkoutStep(duration: 2100, targetPowerPercent: 0.55, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.45, type: .cooldown)
        ]
    )
    
    private static let enduranceMid90 = StructuredWorkout(
        name: "Endurance: Mid (90m)",
        description: "90 minutes of mid-intensity endurance at 65% FTP.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 4200, targetPowerPercent: 0.65, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let enduranceHigh2h = StructuredWorkout(
        name: "Endurance: High (2h)",
        description: "2 hours of high-intensity endurance at 75% FTP.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.55, type: .warmup),
            WorkoutStep(duration: 5400, targetPowerPercent: 0.75, type: .work),
            WorkoutStep(duration: 900, targetPowerPercent: 0.55, type: .cooldown)
        ]
    )
    
    private static let enduranceMid3h = StructuredWorkout(
        name: "Endurance: Mid (3h)",
        description: "3 hours of mid-intensity endurance at 65% FTP.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 9000, targetPowerPercent: 0.65, type: .work),
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let enduranceMid5h = StructuredWorkout(
        name: "Endurance: Mid (5h)",
        description: "Long 5 hour endurance ride at 65% FTP.",
        steps: [
            WorkoutStep(duration: 1800, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 14400, targetPowerPercent: 0.65, type: .work),
            WorkoutStep(duration: 1800, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    // MARK: - Zone 3: Tempo (76-90% FTP)
    
    private static let tempo2x20 = StructuredWorkout(
        name: "Tempo: 2x20m",
        description: "2x20 minute tempo intervals at 85% FTP.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 1200, targetPowerPercent: 0.85, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 1200, targetPowerPercent: 0.85, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let tempo3x15 = StructuredWorkout(
        name: "Tempo: 3x15m",
        description: "3x15 minute tempo intervals at 82% FTP.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 900, targetPowerPercent: 0.82, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 900, targetPowerPercent: 0.82, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 900, targetPowerPercent: 0.82, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    // MARK: - Zone 4: Threshold & Sweet Spot (88-105% FTP)
    
    private static let sweetSpot3x12 = StructuredWorkout(
        name: "Sweet Spot: 3x12m",
        description: "3x12 minute intervals at 90% FTP.",
        steps: [
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 720, targetPowerPercent: 0.90, type: .work),
            WorkoutStep(duration: 240, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 720, targetPowerPercent: 0.90, type: .work),
            WorkoutStep(duration: 240, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 720, targetPowerPercent: 0.90, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let sweetSpot2x20 = StructuredWorkout(
        name: "Sweet Spot: 2x20m",
        description: "2x20 minute intervals at 92% FTP.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 1200, targetPowerPercent: 0.92, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 1200, targetPowerPercent: 0.92, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let thresholdOverUnder3x9 = StructuredWorkout(
        name: "Threshold: 3x9m Over-Under",
        description: "3 sets of 9-min over-unders (2m at 95% / 1m at 105%).",
        steps: {
            var s: [WorkoutStep] = []
            s.append(WorkoutStep(duration: 600, targetPowerPercent: 0.50, endTargetPowerPercent: 0.90, type: .warmup))
            
            for _ in 0..<3 {
                // 9 min block
                for _ in 0..<3 {
                    s.append(WorkoutStep(duration: 120, targetPowerPercent: 0.95, type: .work))
                    s.append(WorkoutStep(duration: 60, targetPowerPercent: 1.05, type: .work))
                }
                s.append(WorkoutStep(duration: 300, targetPowerPercent: 0.50, type: .recovery))
            }
            s.append(WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .cooldown))
            return s
        }()
    )
    
    private static let threshold2x20 = StructuredWorkout(
        name: "Threshold: 2x20m Steady",
        description: "2x20 minute steady threshold intervals at 100% FTP.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 1200, targetPowerPercent: 1.00, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.55, type: .recovery),
            WorkoutStep(duration: 1200, targetPowerPercent: 1.00, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    // MARK: - Zone 5: VO2 Max (106-120% FTP)
    
    private static let vo2max4x4 = StructuredWorkout(
        name: "VO2 Max: 4x4m",
        description: "4x4 minute intervals at 112% FTP.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 240, targetPowerPercent: 1.12, type: .work),
            WorkoutStep(duration: 240, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 240, targetPowerPercent: 1.12, type: .work),
            WorkoutStep(duration: 240, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 240, targetPowerPercent: 1.12, type: .work),
            WorkoutStep(duration: 240, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 240, targetPowerPercent: 1.12, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let vo2max4x5 = StructuredWorkout(
        name: "VO2 Max: 4x5m",
        description: "4x5 minute intervals at 108% FTP.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 300, targetPowerPercent: 1.08, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 300, targetPowerPercent: 1.08, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 300, targetPowerPercent: 1.08, type: .work),
            WorkoutStep(duration: 300, targetPowerPercent: 0.50, type: .recovery),
            WorkoutStep(duration: 300, targetPowerPercent: 1.08, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
        ]
    )
    
    private static let intervals30_30 = StructuredWorkout(
        name: "VO2 Max: 30/30s",
        description: "2 sets of 10x 30s ON / 30s OFF at 120% FTP.",
        steps: {
            var s: [WorkoutStep] = []
            s.append(WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup))
            
            for _ in 0..<2 {
                for _ in 0..<10 {
                    s.append(WorkoutStep(duration: 30, targetPowerPercent: 1.20, type: .work))
                    s.append(WorkoutStep(duration: 30, targetPowerPercent: 0.50, type: .recovery))
                }
                s.append(WorkoutStep(duration: 300, targetPowerPercent: 0.50, type: .recovery))
            }
            
            s.append(WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .cooldown))
            return s
        }()
    )
    
    private static let intervals40_20 = StructuredWorkout(
        name: "VO2 Max: 40/20s",
        description: "2 sets of 8x 40s ON / 20s OFF at 115% FTP.",
        steps: {
            var s: [WorkoutStep] = []
            s.append(WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup))
            
            for _ in 0..<2 {
                for _ in 0..<8 {
                    s.append(WorkoutStep(duration: 40, targetPowerPercent: 1.15, type: .work))
                    s.append(WorkoutStep(duration: 20, targetPowerPercent: 0.50, type: .recovery))
                }
                s.append(WorkoutStep(duration: 300, targetPowerPercent: 0.50, type: .recovery))
            }
            
            s.append(WorkoutStep(duration: 300, targetPowerPercent: 0.40, type: .cooldown))
            return s
        }()
    )
    
    // MARK: - Zone 6: Anaerobic (>121% FTP)
    
    private static let anaerobicSprints = StructuredWorkout(
        name: "Anaerobic: 30s Sprints",
        description: "5x 30s maximal sprints at 150% FTP.",
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
    
    private static let anaerobicPower30_30 = StructuredWorkout(
        name: "Anaerobic: 30/30s Power",
        description: "12x 30s ON at 130% FTP / 30s OFF at 50% FTP.",
        steps: {
            var s: [WorkoutStep] = []
            s.append(WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .warmup))
            for _ in 0..<12 {
                s.append(WorkoutStep(duration: 30, targetPowerPercent: 1.30, type: .work))
                s.append(WorkoutStep(duration: 30, targetPowerPercent: 0.50, type: .recovery))
            }
            s.append(WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown))
            return s
        }()
    )
    
    // MARK: - Zone 7: Neuromuscular Power
    
    private static let neuromuscularMaxSprints = StructuredWorkout(
        name: "Neuromuscular: 15s Max Sprints",
        description: "Maximal 15s neuromuscular efforts with full recovery.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 15, targetPowerPercent: 2.00, type: .work),
            WorkoutStep(duration: 480, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 15, targetPowerPercent: 2.00, type: .work),
            WorkoutStep(duration: 480, targetPowerPercent: 0.40, type: .recovery),
            WorkoutStep(duration: 15, targetPowerPercent: 2.00, type: .work),
            WorkoutStep(duration: 600, targetPowerPercent: 0.50, type: .cooldown)
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
    
    private static let gabriel = StructuredWorkout(
        name: "Gabriel",
        description: "120 minutes of aerobic endurance training. This workout aims to build your aerobic base and improve fat metabolism through long, steady-state intervals in Zone 2.",
        steps: [
            WorkoutStep(duration: 900, targetPowerPercent: 0.50, type: .warmup),
            WorkoutStep(duration: 5940, targetPowerPercent: 0.60, type: .work),
            WorkoutStep(duration: 360, targetPowerPercent: 0.50, type: .cooldown)
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
    
    private static let hrTest = StructuredWorkout(
        name: "HR Target Test",
        description: "A workout focused on maintaining specific heart rate targets. The trainer will adjust power to hit the HR goals.",
        steps: [
            WorkoutStep(duration: 300, targetHeartRatePercent: 0.70, type: .warmup),
            WorkoutStep(duration: 600, targetHeartRatePercent: 0.85, type: .work), // 85% LTHR
            WorkoutStep(duration: 300, targetHeartRatePercent: 0.70, type: .cooldown)
        ]
    )
}
