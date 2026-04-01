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
    
    // MARK: - PID State
    
    private var currentControlWatts: Double?
    private var lastError: Double = 0
    private var lastUpdate: Date?
    private var filteredHR: Double?
    private var activeHRTarget: Double? // Used to detect if target changed and reset PID
    
    // PID Coefficients (Optimized for Incremental/Velocity form)
    private let Kp = 0.15  // Proportional: Reacts to change in error
    private let Ki = 0.01  // Integral: Handles the slow "crawl" to match HR
    private let Kd = 0.05  // Derivative: Dampens oscillations
    private let hrEmaAlpha = 0.2
    
    public init() {}
    
    public func reset() {
        currentControlWatts = nil
        lastError = 0
        lastUpdate = nil
        filteredHR = nil
        activeHRTarget = nil
    }
    
    public func calculateManualHR(targetHR: Double, currentHR: Int?, ftp: Double) -> Int? {
        let hr = Double(currentHR ?? 0)
        guard hr > 0 else { return Int(round(currentControlWatts ?? ftp * 0.5)) }
        
        let error = targetHR - hr
        var base = currentControlWatts ?? (ftp * 0.5)
        
        // Simple incremental adjustment for manual mode
        let adjustment = error * 0.05 
        base += adjustment
        base = max(50, min(base, ftp * 1.5))
        
        currentControlWatts = base
        return Int(round(base))
    }
    
    public func calculate(input: Input) -> Int? {
        guard !input.isFinished else {
            reset()
            return nil
        }
        
        let now = Date()
        let dt = lastUpdate != nil ? now.timeIntervalSince(lastUpdate!) : 1.0
        lastUpdate = now
        
        // 1. Determine the "Goal" Strategy
        let strategyWatts: Double
        
        if let hrPercent = input.currentStep.targetHeartRatePercent {
            let targetHR = hrPercent * input.difficultyScale * input.lthr
            let expectedPower = getInitialPowerForHR(hrPercent: hrPercent * input.difficultyScale, ftp: input.ftp)
            
            // Initialization / Target Change
            if activeHRTarget != targetHR {
                if activeHRTarget == nil {
                    // Fresh start: Jump to expected power immediately
                    currentControlWatts = expectedPower
                }
                activeHRTarget = targetHR
                lastError = 0
            }
            
            if let hrRaw = input.currentHR, hrRaw > 0 {
                let hr = filteredHR != nil ? (Double(hrRaw) * hrEmaAlpha + filteredHR! * (1.0 - hrEmaAlpha)) : Double(hrRaw)
                filteredHR = hr
                
                let error = targetHR - hr
                let errorChange = error - lastError
                lastError = error
                
                // Incremental PID Logic
                var pTerm = errorChange * Kp * (input.ftp / 10.0) // Scaled by fitness
                let iTerm = error * Ki * dt * (input.ftp / 10.0)
                
                // Dynamic Damping
                var gainMultiplier = 1.0
                let currentWatts = currentControlWatts ?? expectedPower
                
                if error > 0 && currentWatts > expectedPower {
                    let overshoot = (currentWatts - expectedPower) / input.ftp
                    if overshoot > 0.05 {
                        gainMultiplier = 0.2
                    }
                }
                
                if error < -2 {
                    gainMultiplier = 1.5 
                }
                
                let adjustment = (pTerm + iTerm) * gainMultiplier
                var base = currentWatts + adjustment
                
                let relativeCap = expectedPower + (input.ftp * 0.2)
                base = max(50, min(base, min(input.ftp * 1.5, relativeCap)))
                
                currentControlWatts = base
            }
            
            strategyWatts = currentControlWatts ?? expectedPower
            
        } else {
            // Power Mode
            activeHRTarget = nil
            filteredHR = nil
            strategyWatts = (input.currentStep.powerAt(time: input.timeInStep) ?? 0) * input.difficultyScale * input.ftp
        }
        
        // 2. Apply Hardware Adjustments (Anticipatory Logic)
        var commandedWatts = strategyWatts
        
        if let next = input.nextStep {
            let timeRemaining = input.currentStep.duration - input.timeInStep
            
            if timeRemaining <= input.lookaheadSeconds {
                // Determine what the next step's starting power will be
                let nextStartPower: Double
                if let nextHRPercent = next.targetHeartRatePercent {
                    nextStartPower = getInitialPowerForHR(hrPercent: nextHRPercent * input.difficultyScale, ftp: input.ftp)
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
    
    // MARK: - Private Helpers
    
    private func getInitialPowerForHR(hrPercent: Double, ftp: Double) -> Double {
        let hrZone = WorkoutZone.forHRIntensity(hrPercent)
        
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
        
        return powerIntensity * ftp
    }
}
