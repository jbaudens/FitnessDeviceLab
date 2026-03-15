import Foundation

public struct TargetPowerCalculator {
    public struct Input {
        public let step: WorkoutStep
        public let timeInStep: TimeInterval
        public let isFinished: Bool
        public let ftp: Double
        public let lthr: Double
        public let difficultyScale: Double
        public let ergModeEnabled: Bool
        public let currentHR: Int?
        public let previousHRControlBaseWatts: Double?
        
        public init(step: WorkoutStep, timeInStep: TimeInterval, isFinished: Bool, ftp: Double, lthr: Double, difficultyScale: Double, ergModeEnabled: Bool, currentHR: Int?, previousHRControlBaseWatts: Double?) {
            self.step = step
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
        public let targetPower: Int?
        public let targetHR: Int?
        public let newHRControlBaseWatts: Double?
        
        public init(targetPower: Int?, targetHR: Int?, newHRControlBaseWatts: Double?) {
            self.targetPower = targetPower
            self.targetHR = targetHR
            self.newHRControlBaseWatts = newHRControlBaseWatts
        }
    }
    
    public static func calculate(input: Input) -> Result {
        if input.isFinished {
            return Result(targetPower: nil, targetHR: nil, newHRControlBaseWatts: nil)
        }
        
        var currentTargetPower: Int? = nil
        var currentTargetHR: Int? = nil
        var hrControlBaseWatts = input.previousHRControlBaseWatts
        
        if let targetHRPercent = input.step.targetHeartRatePercent {
            let targetHRValue = Int(round(targetHRPercent * input.difficultyScale * input.lthr))
            currentTargetHR = targetHRValue
            
            if input.ergModeEnabled {
                if let hr = input.currentHR, hr > 0 {
                    var base = hrControlBaseWatts ?? (input.ftp * 0.5)
                    let error = Double(targetHRValue) - Double(hr)
                    let adjustment = error * 0.15
                    base += adjustment
                    base = max(50, min(base, input.ftp * 1.5))
                    hrControlBaseWatts = base
                }
            }
            
            if let base = hrControlBaseWatts {
                currentTargetPower = Int(round(base))
            }
        } else {
            let watts = Int(round((input.step.powerAt(time: input.timeInStep) ?? 0) * input.difficultyScale * input.ftp))
            currentTargetPower = watts
            currentTargetHR = nil
            hrControlBaseWatts = nil
        }
        
        return Result(
            targetPower: currentTargetPower,
            targetHR: currentTargetHR,
            newHRControlBaseWatts: hrControlBaseWatts
        )
    }
}
