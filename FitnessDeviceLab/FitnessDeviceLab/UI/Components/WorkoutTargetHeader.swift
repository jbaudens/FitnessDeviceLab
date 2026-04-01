import SwiftUI

struct WorkoutTargetHeader: View {
    @Bindable var workoutManager: WorkoutSessionManager
    let workout: StructuredWorkout
    
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .medium
        return df
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                // Time in Interval
                if let step = workoutManager.currentWorkoutStep {
                    let isFinished = workoutManager.currentTargetPower == nil && workoutManager.currentTargetHR == nil && workoutManager.isRecording
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            let remainingTime = step.duration - workoutManager.timeInStep
                            let isCountdown = remainingTime > 0 && remainingTime <= 5.0 && !isFinished
                            
                            Text(isFinished ? "0:00" : formatDuration(remainingTime))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(isCountdown ? .orange : .primary)
                                .scaleEffect(isCountdown ? 1.1 : 1.0)
                                .animation(.spring(), value: isCountdown)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("LAP \(max(1, workoutManager.laps.count))")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.blue)
                                Text(formatDuration(workoutManager.laps.last?.duration ?? 0))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text("REMAINING IN STEP")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Session Progress in Middle
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            if let start = workoutManager.sessionStartTime {
                                Text("S: \(timeFormatter.string(from: start))")
                            }
                            
                            let remaining = workout.totalDuration - workoutManager.workoutElapsedTime
                            let estimatedEnd = Date().addingTimeInterval(remaining)
                            Text("E: \(timeFormatter.string(from: estimatedEnd))")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)

                        Text("\(formatDuration(workoutManager.workoutElapsedTime)) / \(formatDuration(workout.totalDuration))")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        ProgressView(value: min(1.0, workoutManager.workoutElapsedTime / workout.totalDuration))
                            .tint(.blue)
                            .frame(width: 120)
                            .scaleEffect(x: 1, y: 0.5)
                    }
                    
                    Spacer()
                    
                    // Target Power / HR
                    HStack(spacing: 20) {
                        if let targetHR = workoutManager.currentTargetHR {
                            VStack(alignment: .trailing, spacing: 2) {
                                let scale = workoutManager.workoutDifficultyScale
                                let currentIntensity = (workoutManager.currentWorkoutStep?.targetHeartRatePercent ?? 0) * scale

                                Text("\(targetHR)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(WorkoutZone.forHRIntensity(currentIntensity).color)
                                Text("GOAL BPM")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.secondary)
                            }

                            if let commandedWatts = workoutManager.currentTargetPower {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(commandedWatts)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                    Text("TARGET W")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else if let targetWatts = workoutManager.currentTargetPower {
                            VStack(alignment: .trailing, spacing: 2) {
                                let scale = workoutManager.workoutDifficultyScale
                                let currentIntensity = (workoutManager.currentWorkoutStep?.powerAt(time: workoutManager.timeInStep) ?? 0) * scale

                                Text("\(targetWatts)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(WorkoutZone.forIntensity(currentIntensity).color)
                                Text("TARGET WATTS")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("0")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                                Text("FINISHED")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                }
            }
            
            if workoutManager.currentStepIndex < workout.steps.count - 1 {
                let nextStep = workout.steps[workoutManager.currentStepIndex + 1]
                let scale = workoutManager.workoutDifficultyScale
                
                HStack {
                    Spacer()
                    if let hrPct = nextStep.targetHeartRatePercent {
                        let nextHR = Int(round(hrPct * scale * Double(workoutManager.settings.userLTHR)))
                        Text("Next: \(nextHR)bpm (\(Int(round(hrPct * scale * 100)))%) for \(Int(nextStep.duration / 60))m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        let nextWatts = Int(round((nextStep.targetPowerPercent ?? 0.0) * scale * workoutManager.settings.userFTP))
                        Text("Next: \(nextWatts)W (\(Int(round((nextStep.targetPowerPercent ?? 0.0) * scale * 100)))%) for \(Int(nextStep.duration / 60))m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
