import Foundation

/// A focused calculator to determine the specific wattage setpoint to be sent to a smart trainer.
/// This handles the logic of "how to achieve the goal" (e.g., PID for HR, look-ahead for transitions).
public class TrainerSetpointCalculator {
    public struct Input {
        /// The current active step in the workout.
        public let currentStep: WorkoutStep
        /// The next upcoming step (if any) to allow for anticipatory logic.
        public let nextStep: WorkoutStep?
        /// How far into the current step we are (seconds).
        public let timeInStep: TimeInterval
        /// Whether the workout has reached its end.
        public let isFinished: Bool
        /// The user's Functional Threshold Power.
        public let ftp: Double
        /// The user's Lactate Threshold Heart Rate.
        public let lthr: Double
        /// Current workout difficulty multiplier (0.5 to 2.0).
        public let difficultyScale: Double
        /// The latest heart rate reading from the primary sensor.
        public let currentHR: Int?
        /// How many seconds before a step transition to start the ramp (trainer responsiveness).
        public let lookaheadSeconds: Double = 2.0
        
        public init(currentStep: WorkoutStep, nextStep: WorkoutStep?, timeInStep: TimeInterval, isFinished: Bool, ftp: Double, lthr: Double, difficultyScale: Double, currentHR: Int?) {
            self.currentStep = currentStep
            self.nextStep = nextStep
            self.timeInStep = timeInStep
            self.isFinished = isFinished
            self.ftp = ftp
            self.lthr = lthr
            self.difficultyScale = difficultyScale
            self.currentHR = currentHR
        }
    }
    
    /// Internal state for HR control base wattage
    private var hrControlBaseWatts: Double?
    
    public init() {}
    
    public func reset() {
        hrControlBaseWatts = nil
    }
    
    public func calculateManualHR(targetHR: Double, currentHR: Int?, ftp: Double) -> Int? {
        var base = hrControlBaseWatts ?? (ftp * 0.5)
        
        if let hr = currentHR, hr > 0 {
            let error = targetHR - Double(hr)
            let adjustment = error * 0.15 // Simple proportional adjustment
            base += adjustment
            base = max(50, min(base, ftp * 1.5))
        }
        
        hrControlBaseWatts = base
        return Int(round(base))
    }
    
    public func calculate(input: Input) -> Int? {
        guard !input.isFinished else {
            hrControlBaseWatts = nil
            return nil
        }
        
        // 1. Calculate the "Goal" Strategy (Internal wattage needed for current goal)
        let strategyWatts: Double
        if let hrPercent = input.currentStep.targetHeartRatePercent {
            // HR Mode: Setpoint comes from a simple controller
            let targetHR = hrPercent * input.difficultyScale * input.lthr
            var base = hrControlBaseWatts ?? (input.ftp * 0.5)
            
            if let hr = input.currentHR, hr > 0 {
                let error = targetHR - Double(hr)
                let adjustment = error * 0.15 // Simple proportional adjustment
                base += adjustment
                base = max(50, min(base, input.ftp * 1.5))
            }
            strategyWatts = base
            hrControlBaseWatts = base
        } else {
            // Power Mode: Direct calculation from step definition
            strategyWatts = (input.currentStep.powerAt(time: input.timeInStep) ?? 0) * input.difficultyScale * input.ftp
            // Note: we don't clear hrControlBaseWatts here to allow for continuity if 
            // the workout toggles back and forth, but it's not used for Power steps.
        }
        
        // 2. Apply Hardware Adjustments (Anticipatory Logic)
        var commandedWatts = strategyWatts
        
        if let next = input.nextStep {
            let timeRemaining = input.currentStep.duration - input.timeInStep
            
            if timeRemaining <= input.lookaheadSeconds {
                // Determine what the next step's starting power will be
                let nextStartPower: Double
                if let nextHRPercent = next.targetHeartRatePercent {
                    // Approximate power for an HR goal using zone correlation
                    // We find which HR zone the target is in, and use the mid-point of the equivalent power zone.
                    let targetHR = nextHRPercent * input.difficultyScale
                    let hrZone = WorkoutZone.forHRIntensity(targetHR)
                    
                    // Equivalent power intensities for zones (midpoints)
                    let powerIntensity: Double
                    switch hrZone {
                    case .z1: powerIntensity = 0.50
                    case .z2: powerIntensity = 0.65
                    case .z3: powerIntensity = 0.82
                    case .z4: powerIntensity = 0.97
                    case .z5: powerIntensity = 1.12
                    case .z6: powerIntensity = 1.35
                    case .z7: powerIntensity = 1.60
                    }
                    nextStartPower = powerIntensity * input.ftp * input.difficultyScale
                } else {
                    nextStartPower = (next.targetPowerPercent ?? 0) * input.difficultyScale * input.ftp
                }
                
                // Blend from current strategy to next step's start over the lookahead window
                let blendFactor = 1.0 - (timeRemaining / input.lookaheadSeconds)
                commandedWatts = strategyWatts + (nextStartPower - strategyWatts) * blendFactor
            }
        }
        
        return Int(round(commandedWatts))
    }
}
