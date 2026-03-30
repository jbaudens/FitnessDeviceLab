import SwiftUI

struct LapsHistoryView: View {
    @Bindable var workoutManager: WorkoutSessionManager
    let settings: SettingsProvider
    
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeStyle = .medium
        return df
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Laps History")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(workoutManager.laps.reversed()) { lap in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Lap \(lap.index + 1)")
                                .fontWeight(.bold)
                            
                            Text(lap.type.rawValue.uppercased())
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)

                            if lap.index == workoutManager.laps.count - 1 {
                                Text("CURRENT")
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(timeFormatter.string(from: lap.startTime))
                                    Text("-")
                                    if let end = lap.endTime {
                                        Text(timeFormatter.string(from: end))
                                    } else {
                                        Text("Now")
                                    }
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                
                                Text("Duration: \(formatDuration(lap.duration))")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .monospacedDigit()
                        
                        // Lap Summary Table (A vs B)
                        HStack(spacing: 20) {
                            if workoutManager.recorderA.hasAnySensor {
                                LapSummaryColumn(label: "SET A", lap: lap, settings: settings, recorder: workoutManager.recorderA, color: .blue)
                            }
                            
                            if workoutManager.recorderA.hasAnySensor && workoutManager.recorderB.hasAnySensor {
                                Divider()
                            }
                            
                            if workoutManager.recorderB.hasAnySensor {
                                LapSummaryColumn(label: "SET B", lap: lap, settings: settings, recorder: workoutManager.recorderB, color: .purple)
                            }
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    func formatDuration(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct LapSummaryColumn: View {
    let label: String
    let lap: Lap
    let settings: SettingsProvider
    let recorder: SessionRecorder
    let color: Color
    
    var body: some View {
        let points = recorder.trackpoints.filter { 
            $0.time >= lap.startTime && (lap.endTime == nil || $0.time < lap.endTime!)
        }
        let (m, _) = DataFieldEngine.calculate(from: points, settings: settings.metricsSettings)
        
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                // Power row
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").foregroundColor(.yellow)
                    Text("\(Int(round(m.standard.avgPower ?? 0)))").bold()
                    Text("[\(m.standard.minPower ?? 0)-\(m.standard.maxPower ?? 0)]").font(.caption2).foregroundColor(.secondary)
                    if let np = m.standard.normalizedPower {
                        Text("NP: \(Int(round(np)))").font(.caption2).foregroundColor(.orange)
                    }
                }
                
                // HR row
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").foregroundColor(.red)
                    Text("\(Int(round(m.hr.avg ?? 0)))").bold()
                    Text("[\(m.hr.min ?? 0)-\(m.hr.max ?? 0)]").font(.caption2).foregroundColor(.secondary)
                }
                
                // Cadence row
                HStack(spacing: 4) {
                    Image(systemName: "bicycle").foregroundColor(.blue)
                    Text("\(Int(round(m.cadence.avg ?? 0)))").bold()
                    Text("[\(m.cadence.min ?? 0)-\(m.cadence.max ?? 0)]").font(.caption2).foregroundColor(.secondary)
                }
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
        }
    }
}
