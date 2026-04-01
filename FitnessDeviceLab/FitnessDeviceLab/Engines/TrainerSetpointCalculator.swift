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
    private var integralSum: Double = 0
    private var lastError: Double = 0
    private var lastUpdate: Date?
    private var filteredHR: Double?
    private var activeHRTarget: Double? // Used to detect if target changed and reset PID
    
    // PID Coefficients (tuned for slow HR response)
    private let Kp = 0.40  // Proportional: Immediate response
    private let Ki = 0.02  // Integral: Handles drift / steady-state error
    private let Kd = 0.15  // Derivative: Damping to prevent overshoot
    private let hrEmaAlpha = 0.2 // Smoothing for HR (EMA)
    
    public init() {}
    
    public func reset() {
        currentControlWatts = nil
        integralSum = 0
        lastError = 0
        lastUpdate = nil
        filteredHR = nil
        activeHRTarget = nil
    }
    
    public func calculateManualHR(targetHR: Double, currentHR: Int?, ftp: Double) -> Int? {
        // Fallback to simple logic for manual HR or refactor to share PID logic if needed
        let hr = Double(currentHR ?? 0)
        guard hr > 0 else { return Int(round(currentControlWatts ?? ftp * 0.5)) }
        
        let error = targetHR - hr
        var base = currentControlWatts ?? (ftp * 0.5)
        base += error * 0.15
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
        
        // 1. Determine the "Goal" Strategy (Internal wattage needed for current goal)
        let strategyWatts: Double
        
        if let hrPercent = input.currentStep.targetHeartRatePercent {
            let targetHR = hrPercent * input.difficultyScale * input.lthr
            
            // Detect target changes to reset integral/derivative components
            if activeHRTarget != targetHR {
                // If we were already in HR mode but target changed, just reset PID state
                // If we are just starting, initialize control watts from feed-forward
                if activeHRTarget == nil {
                    currentControlWatts = getInitialPowerForHR(hrPercent: hrPercent * input.difficultyScale, ftp: input.ftp)
                }
                activeHRTarget = targetHR
                integralSum = 0
                lastError = 0
            }
            
            if let hrRaw = input.currentHR, hrRaw > 0 {
                // Smooth HR to avoid overreacting to noise
                let hr = filteredHR != nil ? (Double(hrRaw) * hrEmaAlpha + filteredHR! * (1.0 - hrEmaAlpha)) : Double(hrRaw)
                filteredHR = hr
                
                let error = targetHR - hr
                
                // Proportional
                let pTerm = error * Kp
                
                // Integral (with anti-windup)
                integralSum += error * dt
                let maxIntegral = input.ftp * 0.3 // Cap integral contribution to 30% of FTP
                integralSum = max(-maxIntegral / Ki, min(integralSum, maxIntegral / Ki))
                let iTerm = integralSum * Ki
                
                // Derivative (Damping)
                let dTerm = ((error - lastError) / dt) * Kd
                lastError = error
                
                // Calculate adjustment in Watts
                // Note: PID output is change in power
                var base = currentControlWatts ?? getInitialPowerForHR(hrPercent: hrPercent * input.difficultyScale, ftp: input.ftp)
                base += (pTerm + iTerm + dTerm)
                
                // Safety bounds: 50W to 150% of FTP
                base = max(50, min(base, input.ftp * 1.5))
                currentControlWatts = base
            }
            
            strategyWatts = currentControlWatts ?? (input.ftp * 0.5)
            
        } else {
            // Power Mode: Direct calculation from step definition
            strategyWatts = (input.currentStep.powerAt(time: input.timeInStep) ?? 0) * input.difficultyScale * input.ftp
            
            // Clean up HR PID state while in Power mode to ensure fresh start later
            activeHRTarget = nil
            filteredHR = nil
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
