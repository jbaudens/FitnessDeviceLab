import SwiftUI
import Charts

struct WorkoutGraphView: View {
    let workout: StructuredWorkout
    let userFTP: Double
    var showAxis: Bool = true
    var elapsedTime: TimeInterval? = nil
    var recorder: SessionRecorder? = nil
    var sessionStartTime: Date? = nil
    var scale: Double = 1.0
    
    init(workout: StructuredWorkout, userFTP: Double, showAxis: Bool = true, elapsedTime: TimeInterval? = nil, recorder: SessionRecorder? = nil, sessionStartTime: Date? = nil, scale: Double = 1.0) {
        self.workout = workout
        self.userFTP = userFTP
        self.showAxis = showAxis
        self.elapsedTime = elapsedTime
        self.recorder = recorder
        self.sessionStartTime = sessionStartTime
        self.scale = scale
    }
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let totalDuration = workout.totalDuration
                let ftp = userFTP
                // Max height is based on the highest interval or highest data point
                let scale = scale
                let maxTarget = workout.steps.map { ($0.targetPowerPercent ?? $0.targetHeartRatePercent ?? 0.0) * scale }.max() ?? 1.0
                let maxActual = recorder?.trackpoints.compactMap { $0.power }.map { Double($0) / ftp }.max() ?? 0.0

                let maxPercent = max(1.0, max(maxTarget, maxActual)) * 1.1
                
                ZStack(alignment: .bottomLeading) {
                    // Background grid lines and labels
                    if showAxis {
                        let increments: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5]
                        ForEach(increments, id: \.self) { pct in
                            if pct < maxPercent {
                                let y = height * (1.0 - (pct / maxPercent))
                                
                                // Grid line
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: width, y: y))
                                }
                                .stroke(Color.secondary.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [2]))
                                
                                // Left label (Watts)
                                Text("\(Int(pct * ftp))")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .position(x: 20, y: y - 6)
                                
                                // Right label (Watts)
                                Text("\(Int(pct * ftp))")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .position(x: width - 20, y: y - 6)
                            }
                        }
                        
                        // Time X-axis increments
                        let timeStep: TimeInterval = totalDuration > 3600 ? 900 : (totalDuration > 1800 ? 600 : 300)
                        ForEach(Array(Swift.stride(from: timeStep, to: totalDuration, by: timeStep)), id: \.self) { t in
                            let x = (CGFloat(t) / CGFloat(totalDuration)) * width
                            Text("\(Int(t/60))m")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.5))
                                .position(x: x, y: height - 6)
                        }
                    }
                    
                    // The target bars (background)
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(workout.steps) { step in
                            let stepWidth = (CGFloat(step.duration) / CGFloat(totalDuration)) * (width - CGFloat(workout.steps.count))
                            
                            let startPct = step.targetPowerPercent ?? step.targetHeartRatePercent ?? 0.0
                            let endPct = step.endTargetPowerPercent ?? step.targetHeartRatePercent ?? 0.0
                            
                            let startHeight = (CGFloat(startPct * scale) / CGFloat(maxPercent)) * height
                            let endHeight = (CGFloat(endPct * scale) / CGFloat(maxPercent)) * height
                            
                            ZStack(alignment: .top) {
                                RampShape(startRelativeHeight: startPct * scale / maxPercent,
                                          endRelativeHeight: endPct * scale / maxPercent)
                                    .fill(color(for: step, scale: scale).opacity(0.3))
                                    .frame(width: max(2, stepWidth), height: height)
                                
                                if stepWidth > 30 {
                                    let avgPercent = (startPct + endPct) / 2.0 * scale
                                    Text("\(Int(round(avgPercent * 100)))%")
                                        .font(.system(size: 8, weight: .black, design: .monospaced))
                                        .foregroundColor(color(for: step, scale: scale).opacity(0.8))
                                        .padding(.top, height - max(startHeight, endHeight) + 4)
                                }
                            }
                        }
                    }
                    
                    // The live data (foreground)
                    if let recorder = recorder {
                        PerformanceChart(
                            recorder: recorder,
                            totalDuration: totalDuration,
                            maxPower: maxPercent * ftp,
                            startTime: sessionStartTime
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
    
    private func color(for step: WorkoutStep, scale: Double) -> Color {
        if let hr = step.targetHeartRatePercent {
            return WorkoutZone.forHRIntensity(hr * scale).color
        }
        let start = step.targetPowerPercent ?? 0
        let end = step.endTargetPowerPercent ?? start
        return WorkoutZone.forIntensity((start + end) / 2.0 * scale).color
    }
}

struct RampShape: Shape {
    let startRelativeHeight: Double
    let endRelativeHeight: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        let w = rect.width
        
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * (1.0 - startRelativeHeight)))
        path.addLine(to: CGPoint(x: w, y: h * (1.0 - endRelativeHeight)))
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        
        return path
    }
}

struct SessionGraphView: View {
    @Bindable var recorder: SessionRecorder
    let userFTP: Double
    var showAxis: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Dynamically determine duration based on points, with a minimum of 5 minutes
                let recordedPoints = Double(recorder.trackpoints.count)
                let totalDuration = max(300, recordedPoints * 1.1) // 10% buffer
                let ftp = userFTP
                
                let maxActual = recorder.trackpoints.compactMap { $0.power }.map { Double($0) / ftp }.max() ?? 0.0
                let maxPercent = max(1.0, maxActual) * 1.1
                
                ZStack(alignment: .bottomLeading) {
                    if showAxis {
                        let increments: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5]
                        ForEach(increments, id: \.self) { pct in
                            if pct < maxPercent {
                                let y = height * (1.0 - (pct / maxPercent))
                                
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: width, y: y))
                                }
                                .stroke(Color.secondary.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [2]))
                                
                                Text("\(Int(pct * ftp))")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .position(x: 20, y: y - 6)
                            }
                        }
                    }
                    
                    GrowingPerformanceChart(
                        recorder: recorder,
                        totalDuration: totalDuration,
                        maxPower: maxPercent * ftp
                    )
                    .frame(width: width, height: height)
                }
            }
        }
    }
}

struct GrowingPerformanceChart: View {
    @Bindable var recorder: SessionRecorder
    let totalDuration: TimeInterval
    let maxPower: Double
    
    private var downsampledTrackpoints: [Trackpoint] {
        let maxPoints = 500
        let totalPoints = recorder.trackpoints.count
        guard totalPoints > maxPoints else { return recorder.trackpoints }
        
        let strideValue = totalPoints / maxPoints
        var result: [Trackpoint] = []
        for i in Swift.stride(from: 0, to: totalPoints, by: strideValue) {
            result.append(recorder.trackpoints[i])
        }
        if let last = recorder.trackpoints.last, result.last?.id != last.id {
            result.append(last)
        }
        return result
    }
    
    var body: some View {
        Chart {
            ForEach(Array(downsampledTrackpoints.enumerated()), id: \.element.id) { index, pt in
                let originalIndex = recorder.trackpoints.firstIndex(where: { $0.id == pt.id }) ?? index
                let timeOffset = Double(originalIndex)
                
                if let pwr = pt.power {
                    LineMark(
                        x: .value("Time", timeOffset),
                        y: .value("Power", min(Double(pwr), 1600)),
                        series: .value("Metric", "Power")
                    )
                    .foregroundStyle(Color.yellow)
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
        .animation(.none, value: recorder.trackpoints.count)
    }
}

struct PerformanceChart: View {
    @Bindable var recorder: SessionRecorder
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
            ForEach(Array(downsampledTrackpoints.enumerated()), id: \.element.id) { index, pt in
                // Find the original index to use as the time offset (1pt = 1s)
                let originalIndex = recorder.trackpoints.firstIndex(where: { $0.id == pt.id }) ?? index
                let timeOffset = Double(originalIndex)
                
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
    let userFTP: Double
    
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
                    
                    HStack(spacing: 6) {
                        Text("\(Int(workout.totalDuration / 60)) min")
                        Text("•")
                        Text("IF \(String(format: "%.2f", workout.intensityFactor))")
                        Text("•")
                        Label(workout.primaryMetric.rawValue, systemImage: workout.primaryMetric == .power ? "bolt.fill" : "heart.fill")
                            .imageScale(.small)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            WorkoutGraphView(workout: workout, userFTP: userFTP, showAxis: false)
                .frame(height: 40)
        }
        .padding(.vertical, 8)
    }
}
