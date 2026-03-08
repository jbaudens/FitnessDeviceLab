import SwiftUI
import Charts

struct WorkoutGraphView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    let workout: StructuredWorkout
    var showAxis: Bool = true
    var elapsedTime: TimeInterval? = nil
    var recorder: SessionRecorder? = nil
    
    init(workout: StructuredWorkout, showAxis: Bool = true, elapsedTime: TimeInterval? = nil, recorder: SessionRecorder? = nil) {
        self.workout = workout
        self.showAxis = showAxis
        self.elapsedTime = elapsedTime
        self.recorder = recorder
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let totalDuration = workout.totalDuration
                
                // Max height is based on the highest interval or highest data point
                let maxTarget = workout.steps.map { $0.targetPowerPercent }.max() ?? 1.0
                let maxActual = recorder?.trackpoints.compactMap { $0.power }.map { Double($0) / SettingsManager.shared.userFTP }.max() ?? 0.0
                let maxPercent = max(1.0, max(maxTarget, maxActual)) * 1.1
                
                ZStack(alignment: .bottomLeading) {
                    // Background grid lines (50%, 100%)
                    if showAxis {
                        Path { path in
                            let y50 = height * (1.0 - (0.5 / maxPercent))
                            let y100 = height * (1.0 - (1.0 / maxPercent))
                            
                            path.move(to: CGPoint(x: 0, y: y50))
                            path.addLine(to: CGPoint(x: width, y: y50))
                            
                            path.move(to: CGPoint(x: 0, y: y100))
                            path.addLine(to: CGPoint(x: width, y: y100))
                        }
                        .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                    
                    // The target bars (background)
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(workout.steps) { step in
                            let stepWidth = (CGFloat(step.duration) / CGFloat(totalDuration)) * (width - CGFloat(workout.steps.count))
                            let stepHeight = (CGFloat(step.targetPowerPercent) / CGFloat(maxPercent)) * height
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color(for: step).opacity(0.3))
                                .frame(width: max(2, stepWidth), height: max(4, stepHeight))
                        }
                    }
                    
                    // The live data (foreground)
                    if let recorder = recorder {
                        PerformanceChart(
                            recorder: recorder,
                            totalDuration: totalDuration,
                            maxPower: maxPercent * SettingsManager.shared.userFTP,
                            startTime: workoutManager.sessionStartTime
                        )
                        .frame(width: width, height: height)
                    }
                    
                    // Playhead
                    if let elapsed = elapsedTime {
                        let playheadX = (CGFloat(elapsed) / CGFloat(totalDuration)) * width
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2)
                            .shadow(radius: 2)
                            .offset(x: playheadX)
                    }
                }
            }
        }
    }
    
    private func color(for step: WorkoutStep) -> Color {
        return WorkoutZone.forIntensity(step.targetPowerPercent).color
    }
}

struct PerformanceChart: View {
    @ObservedObject var recorder: SessionRecorder
    let totalDuration: TimeInterval
    let maxPower: Double
    let startTime: Date?
    
    // Downsampling logic to maintain performance during long sessions
    private var downsampledTrackpoints: [Trackpoint] {
        let maxPoints = 500 // Swift Charts sweet spot for performance
        let totalPoints = recorder.trackpoints.count
        guard totalPoints > maxPoints else { return recorder.trackpoints }
        
        let strideValue = totalPoints / maxPoints
        var result: [Trackpoint] = []
        for i in Swift.stride(from: 0, to: totalPoints, by: strideValue) {
            result.append(recorder.trackpoints[i])
        }
        // Always include the latest point
        if let last = recorder.trackpoints.last, result.last?.id != last.id {
            result.append(last)
        }
        return result
    }
    
    var body: some View {
        Chart {
            ForEach(downsampledTrackpoints) { pt in
                let timeOffset = pt.time.timeIntervalSince(startTime ?? pt.time)
                
                if let pwr = pt.power {
                    LineMark(
                        x: .value("Time", timeOffset),
                        y: .value("Power", min(Double(pwr), 1600)), // Don't clip at 600, allow spikes
                        series: .value("Metric", "Power")
                    )
                    .foregroundStyle(Color.yellow)
                }
                
                if let cad = pt.cadence {
                    LineMark(
                        x: .value("Time", timeOffset),
                        y: .value("Cadence", Double(cad)),
                        series: .value("Metric", "Cadence")
                    )
                    .foregroundStyle(Color.blue)
                }
                
                if let hr = pt.hr {
                    LineMark(
                        x: .value("Time", timeOffset),
                        y: .value("HR", Double(hr)),
                        series: .value("Metric", "HR")
                    )
                    .foregroundStyle(Color.red)
                }
            }
        }
        .chartXScale(domain: 0...totalDuration)
        .chartYScale(domain: 0...maxPower)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .animation(.none, value: recorder.trackpoints.count) // Disable chart animation for performance
    }
}

struct WorkoutRowView: View {
    let workout: StructuredWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(workout.name)
                            .font(.headline)
                        
                        Text("Z\(workout.primaryZone.rawValue)")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(workout.primaryZone.color)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text("\(Int(workout.totalDuration / 60)) min • IF \(String(format: "%.2f", workout.intensityFactor))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            WorkoutGraphView(workout: workout, showAxis: false)
                .frame(height: 40)
        }
        .padding(.vertical, 8)
    }
}
