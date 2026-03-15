import Testing
import Foundation
@testable import FitnessDeviceLab

@MainActor
struct TrainerSetpointCalculatorTests {

    @Test func testConstantPowerStep() async throws {
        let calculator = TrainerSetpointCalculator()
        let step = WorkoutStep(duration: 60, targetPowerPercent: 0.5) // 50% FTP
        let input = TrainerSetpointCalculator.Input(
            currentStep: step,
            nextStep: nil,
            timeInStep: 10,
            isFinished: false,
            ftp: 200,
            lthr: 170,
            difficultyScale: 1.0,
            currentHR: nil
        )
        
        let setpoint = calculator.calculate(input: input)
        #expect(setpoint == 100) // 50% of 200
    }
    
    @Test func testDifficultyScaling() async throws {
        let calculator = TrainerSetpointCalculator()
        let step = WorkoutStep(duration: 60, targetPowerPercent: 0.5) // 50% FTP
        let input = TrainerSetpointCalculator.Input(
            currentStep: step,
            nextStep: nil,
            timeInStep: 10,
            isFinished: false,
            ftp: 200,
            lthr: 170,
            difficultyScale: 1.1, // +10%
            currentHR: nil
        )
        
        let setpoint = calculator.calculate(input: input)
        #expect(setpoint == 110) // 55% of 200
    }
    
    @Test func testRampPowerStep() async throws {
        let calculator = TrainerSetpointCalculator()
        // Ramp from 50% to 100% over 100s
        let step = WorkoutStep(duration: 100, targetPowerPercent: 0.5, endTargetPowerPercent: 1.0)
        
        // At 50s, should be 75% FTP
        let input = TrainerSetpointCalculator.Input(
            currentStep: step,
            nextStep: nil,
            timeInStep: 50,
            isFinished: false,
            ftp: 200,
            lthr: 170,
            difficultyScale: 1.0,
            currentHR: nil
        )
        
        let setpoint = calculator.calculate(input: input)
        #expect(setpoint == 150) // 75% of 200
    }
    
    @Test func testHRControlInitialBase() async throws {
        let calculator = TrainerSetpointCalculator()
        let step = WorkoutStep(duration: 60, targetHeartRatePercent: 0.8) // 80% LTHR
        let input = TrainerSetpointCalculator.Input(
            currentStep: step,
            nextStep: nil,
            timeInStep: 0,
            isFinished: false,
            ftp: 200,
            lthr: 170,
            difficultyScale: 1.0,
            currentHR: nil
        )
        
        let setpoint = calculator.calculate(input: input)
        // Initial base is 50% FTP if none provided
        #expect(setpoint == 100)
    }
    
    @Test func testHRControlAdjustment() async throws {
        let calculator = TrainerSetpointCalculator()
        let step = WorkoutStep(duration: 60, targetHeartRatePercent: 0.8) // 80% LTHR = 136 BPM
        
        // 1st tick: Initial base (100W)
        // Target HR = 136. Current HR = 130. Error = 6. Adjustment = 6 * 0.15 = 0.9.
        // New base = 100.9
        let input1 = TrainerSetpointCalculator.Input(
            currentStep: step,
            nextStep: nil,
            timeInStep: 0,
            isFinished: false,
            ftp: 200,
            lthr: 170,
            difficultyScale: 1.0,
            currentHR: 130 
        )
        let setpoint1 = calculator.calculate(input: input1)
        #expect(setpoint1 == 101) // round(100.9)
        
        // 2nd tick: 
        // Current base = 100.9. Error = 6. Adjustment = 0.9.
        // New base = 100.9 + 0.9 = 101.8
        let input2 = TrainerSetpointCalculator.Input(
            currentStep: step,
            nextStep: nil,
            timeInStep: 1,
            isFinished: false,
            ftp: 200,
            lthr: 170,
            difficultyScale: 1.0,
            currentHR: 130
        )
        let setpoint2 = calculator.calculate(input: input2)
        #expect(setpoint2 == 102) // round(101.8)
    }
    
    @Test func testLookaheadAnticipation() async throws {
        let calculator = TrainerSetpointCalculator()
        let currentStep = WorkoutStep(duration: 60, targetPowerPercent: 0.5) // 100W
        let nextStep = WorkoutStep(duration: 60, targetPowerPercent: 1.0) // 200W
        
        // At 59s (within 2s lookahead window)
        // timeRemaining = 1.0. blendFactor = 1.0 - (1.0/2.0) = 0.5
        // commanded = 100 + (200 - 100) * 0.5 = 150
        let input = TrainerSetpointCalculator.Input(
            currentStep: currentStep,
            nextStep: nextStep,
            timeInStep: 59,
            isFinished: false,
            ftp: 200,
            lthr: 170,
            difficultyScale: 1.0,
            currentHR: nil
        )
        
        let setpoint = calculator.calculate(input: input)
        #expect(setpoint == 150)
    }
    
    @Test func testLookaheadHRZoneCorrelation() async throws {
        let calculator = TrainerSetpointCalculator()
        let currentStep = WorkoutStep(duration: 60, targetPowerPercent: 0.5) // 100W
        
        // Next step is HR Zone 4 (Sub-Threshold)
        // Target is 97% LTHR (0.97) -> Z4
        // Equivalent Power Z4 midpoint = 0.97 FTP
        let nextStep = WorkoutStep(duration: 60, targetHeartRatePercent: 0.97) 
        
        // At 59s: timeRemaining = 1.0, blendFactor = 0.5
        // current = 100W
        // nextStartPower = 0.97 * 200 = 194W
        // expected = 100 + (194 - 100) * 0.5 = 147
        let input = TrainerSetpointCalculator.Input(
            currentStep: currentStep,
            nextStep: nextStep,
            timeInStep: 59,
            isFinished: false,
            ftp: 200,
            lthr: 170,
            difficultyScale: 1.0,
            currentHR: nil
        )
        
        let setpoint = calculator.calculate(input: input)
        #expect(setpoint == 147)
    }
}
