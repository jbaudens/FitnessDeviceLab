import Foundation

public class HardwareOrchestrator {
    private let trainerController: TrainerController
    private let setpointCalculator: TrainerSetpointCalculator
    private let settings: SettingsProvider
    
    public init(trainerController: TrainerController, setpointCalculator: TrainerSetpointCalculator, settings: SettingsProvider) {
        self.trainerController = trainerController
        self.setpointCalculator = setpointCalculator
        self.settings = settings
    }
    
    public func update(
        selectedWorkout: StructuredWorkout?,
        freeRideMode: FreeRideControlMode,
        manualTargetPower: Int,
        manualTargetHR: Int,
        resistanceLevel: Double,
        ergModeEnabled: Bool,
        workoutStep: WorkoutStep?,
        nextStep: WorkoutStep?,
        timeInStep: TimeInterval,
        isFinished: Bool,
        difficultyScale: Double,
        currentHR: Int?
    ) -> (power: Int?, hr: Int?) {
        let ftp = settings.userFTP
        let lthr = Double(settings.userLTHR)
        
        if let step = workoutStep {
            // Structured Workout Logic
            let targetPower: Int?
            let targetHR: Int?
            
            if let hrPercent = step.targetHeartRatePercent {
                targetHR = Int(round(hrPercent * difficultyScale * lthr))
                targetPower = nil
            } else {
                targetPower = Int(round((step.powerAt(time: timeInStep) ?? 0) * difficultyScale * ftp))
                targetHR = nil
            }
            
            if ergModeEnabled {
                let input = TrainerSetpointCalculator.Input(
                    currentStep: step,
                    nextStep: nextStep,
                    timeInStep: timeInStep,
                    isFinished: isFinished,
                    ftp: ftp,
                    lthr: lthr,
                    difficultyScale: difficultyScale,
                    currentHR: currentHR
                )
                
                if let targetWatts = setpointCalculator.calculate(input: input) {
                    trainerController.setTargetPower(targetWatts)
                    return (power: step.targetHeartRatePercent != nil ? targetWatts : targetPower, hr: targetHR)
                }
            } else {
                trainerController.setResistanceLevel(resistanceLevel)
            }
            return (power: targetPower, hr: targetHR)
            
        } else {
            // Free Ride Logic
            switch freeRideMode {
            case .resistance:
                trainerController.setResistanceLevel(resistanceLevel)
                return (power: nil, hr: nil)
            case .power:
                trainerController.setTargetPower(manualTargetPower)
                return (power: manualTargetPower, hr: nil)
            case .heartRate:
                let targetWatts = setpointCalculator.calculateManualHR(
                    targetHR: Double(manualTargetHR),
                    currentHR: currentHR,
                    ftp: ftp
                )
                if let watts = targetWatts {
                    trainerController.setTargetPower(watts)
                }
                return (power: targetWatts, hr: manualTargetHR)
            }
        }
    }
}
