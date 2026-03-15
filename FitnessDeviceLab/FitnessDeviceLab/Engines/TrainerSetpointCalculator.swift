import Foundation

/// A focused calculator to determine the specific wattage setpoint to be sent to a smart trainer.
/// This handles the logic of "how to achieve the goal" (e.g., PID for HR, look-ahead for transitions).
public struct TrainerSetpointCalculator {
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
        /// Whether the smart trainer is in ERG mode.
        public let ergModeEnabled: Bool
        /// The latest heart rate reading from the primary sensor.
        public let currentHR: Int?
        /// The previously calculated base wattage for HR control, to maintain continuity.
        public let previousHRControlBaseWatts: Double?
        /// How many seconds before a step transition to start the ramp (trainer responsiveness).
        public let lookaheadSeconds: Double = 2.0
        
        public init(currentStep: WorkoutStep, nextStep: WorkoutStep?, timeInStep: TimeInterval, isFinished: Bool, ftp: Double, lthr: Double, difficultyScale: Double, ergModeEnabled: Bool, currentHR: Int?, previousHRControlBaseWatts: Double?) {
            self.currentStep = currentStep
            self.nextStep = nextStep
            self.timeInStep = timeInStep
            self.isFinished = isFinished
            self.ftp = ftp
            self.lthr = lthr
            self.difficultyScale = difficultyScale
            self.ergModeEnabled = ergModeEnabled
            self.currentHR = currentHR
            self.previousHRControlBaseWatts = previousHRControlBaseWatts
        }
    }
    
    public struct Result {
        /// The actual wattage command to send to the trainer.
        public let setpointWatts: Int?
        /// The updated base wattage for HR control (internal state).
        public let newHRControlBaseWatts: Double?
        
        public init(setpointWatts: Int?, newHRControlBaseWatts: Double?) {
            self.setpointWatts = setpointWatts
            self.newHRControlBaseWatts = newHRControlBaseWatts
        }
    }
    
    public static func calculate(input: Input) -> Result {
        guard !input.isFinished, input.ergModeEnabled else {
            return Result(setpointWatts: nil, newHRControlBaseWatts: nil)
        }
        
        // 1. Calculate the "Goal" Strategy (Internal wattage needed for current goal)
        var strategyWatts: Double?
        if let hrPercent = input.currentStep.targetHeartRatePercent {
            // HR Mode: Setpoint comes from a simple controller
            let targetHR = hrPercent * input.difficultyScale * input.lthr
            var base = input.previousHRControlBaseWatts ?? (input.ftp * 0.5)
            
            if let hr = input.currentHR, hr > 0 {
                let error = targetHR - Double(hr)
                let adjustment = error * 0.15 // Simple proportional adjustment
                base += adjustment
                base = max(50, min(base, input.ftp * 1.5))
            }
            strategyWatts = base
        } else {
            // Power Mode: Direct calculation from step definition
            strategyWatts = (input.currentStep.powerAt(time: input.timeInStep) ?? 0) * input.difficultyScale * input.ftp
        }
        
        // 2. Apply Hardware Adjustments (Anticipatory Logic)
        var commandedWatts = strategyWatts
        
        if let next = input.nextStep, let current = strategyWatts {
            let timeRemaining = input.currentStep.duration - input.timeInStep
            
            if timeRemaining <= input.lookaheadSeconds {
                // Determine what the next step's starting power will be
                let nextStartPower: Double
                if let nextHR = next.targetHeartRatePercent {
                    // If moving into an HR step, we don't know the final power yet, 
                    // so we use a reasonable starting point (50% FTP).
                    nextStartPower = 0.5 * input.difficultyScale * input.ftp
                } else {
                    nextStartPower = (next.targetPowerPercent ?? 0) * input.difficultyScale * input.ftp
                }
                
                // Blend from current strategy to next step's start over the lookahead window
                let blendFactor = 1.0 - (timeRemaining / input.lookaheadSeconds)
                commandedWatts = current + (nextStartPower - current) * blendFactor
            }
        }
        
        return Result(
            setpointWatts: commandedWatts.map { Int(round($0)) },
            newHRControlBaseWatts: input.currentStep.targetHeartRatePercent != nil ? strategyWatts : nil
        )
    }
}
