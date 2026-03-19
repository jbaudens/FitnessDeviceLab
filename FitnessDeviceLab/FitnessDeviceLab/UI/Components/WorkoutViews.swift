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
                let totalHeight = geometry.size.height
                let labelAreaHeight: CGFloat = showAxis ? 20 : 0
                let chartHeight = totalHeight - labelAreaHeight
                
                let totalDuration = workout.totalDuration
                let ftp = userFTP
                
                // Max height is based on the highest interval or highest data point (all in relative units)
                let maxTarget = workout.steps.map { ($0.targetPowerPercent ?? $0.targetHeartRatePercent ?? 0.0) * scale }.max() ?? 1.0
                let maxActual = recorder?.trackpoints.compactMap { $0.power }.map { Double($0) / ftp }.max() ?? 0.0

                let maxPercent = max(1.0, max(maxTarget, maxActual)) * 1.1
                
                ZStack(alignment: .bottomLeading) {
                    // Background grid lines and labels
                    if showAxis {
                        let increments: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5]
                        ForEach(increments, id: \.self) { pct in
                            if pct < maxPercent {
                                let y = chartHeight * (1.0 - (pct / maxPercent))
                                
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
                                .foregroundColor(.secondary.opacity(0.8))
                                .position(x: x, y: totalHeight - 6) // Absolute bottom
                        }
                    }
                    
                    // The target bars (background)
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(workout.steps) { step in
                            let stepWidth = (CGFloat(step.duration) / CGFloat(totalDuration)) * (width - CGFloat(workout.steps.count))
                            
                            let startPct = step.targetPowerPercent ?? step.targetHeartRatePercent ?? 0.0
                            let endPct = step.endTargetPowerPercent ?? step.targetHeartRatePercent ?? 0.0
                            
                            let startH = (startPct * scale / maxPercent)
                            let endH = (endPct * scale / maxPercent)
                            
                            ZStack(alignment: .top) {
                                RampShape(startRelativeHeight: startH,
                                          endRelativeHeight: endH)
                                    .fill(color(for: step, scale: scale).opacity(0.3))
                                    .frame(width: max(2, stepWidth), height: chartHeight)
                                
                                if stepWidth > 30 {
                                    let avgPercent = (startPct + endPct) / 2.0 * scale
                                    Text("\(Int(round(avgPercent * 100)))%")
                                        .font(.system(size: 8, weight: .black, design: .monospaced))
                                        .foregroundColor(color(for: step, scale: scale).opacity(0.8))
                                        .padding(.top, chartHeight * (1.0 - max(startH, endH)) + 4)
                                }
                            }
                        }
                    }
                    .padding(.bottom, labelAreaHeight)
                    
                    // The live data (foreground)
                    if let recorder = recorder {
                        PerformanceChart(
                            recorder: recorder,
                            totalDuration: totalDuration,
                            maxPercent: maxPercent,
                            userFTP: ftp,
                            startTime: sessionStartTime
                        )
                        .frame(width: width, height: chartHeight)
                        .padding(.bottom, labelAreaHeight)
                    }
                    
                    // Legend Overlay (Only show if axis/detail is requested)
                    if showAxis {
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Spacer()
                                Label("Power", systemImage: "bolt.fill").foregroundColor(.yellow)
                                Label("Cadence", systemImage: "bicycle").foregroundColor(.blue)
                                Label("HR", systemImage: "heart.fill").foregroundColor(.red)
                            }
                            .font(.system(size: 8, weight: .black))
                            .padding(.trailing, 10)
                            .padding(.bottom, labelAreaHeight + 2)
                        }
                    }
                    
                    // Playhead
                    if let elapsed = elapsedTime {
                        let playheadX = (CGFloat(elapsed) / CGFloat(totalDuration)) * width
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: chartHeight)
                            .shadow(radius: 2)
                            .offset(x: playheadX)
                            .padding(.bottom, labelAreaHeight)
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

struct SessionGraphView: View {
    @Bindable var recorder: SessionRecorder
    let userFTP: Double
    var showAxis: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let totalHeight = geometry.size.height
                let labelAreaHeight: CGFloat = showAxis ? 20 : 0
                let chartHeight = totalHeight - labelAreaHeight
                
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
                                let y = chartHeight * (1.0 - (pct / maxPercent))
                                
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
                        
                        // Time X-axis increments
                        let timeStep: TimeInterval = totalDuration > 3600 ? 900 : (totalDuration > 1800 ? 600 : 300)
                        ForEach(Array(Swift.stride(from: timeStep, to: totalDuration, by: timeStep)), id: \.self) { t in
                            let x = (CGFloat(t) / CGFloat(totalDuration)) * width
                            Text("\(Int(t/60))m")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.8))
                                .position(x: x, y: totalHeight - 6)
                        }
                    }
                    
                    PerformanceChart(
                        recorder: recorder,
                        totalDuration: totalDuration,
                        maxPercent: maxPercent,
                        userFTP: ftp,
                        startTime: nil
                    )
                    .frame(width: width, height: chartHeight)
                    .padding(.bottom, labelAreaHeight)
                    
                    // Legend Overlay (Only show if axis/detail is requested)
                    if showAxis {
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Spacer()
                                Label("Power", systemImage: "bolt.fill").foregroundColor(.yellow)
                                Label("Cadence", systemImage: "bicycle").foregroundColor(.blue)
                                Label("HR", systemImage: "heart.fill").foregroundColor(.red)
                            }
                            .font(.system(size: 8, weight: .black))
                            .padding(.trailing, 10)
                            .padding(.bottom, labelAreaHeight + 2)
                        }
                    }
                }
            }
        }
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

struct PerformanceChart: View {
    @Bindable var recorder: SessionRecorder
    let totalDuration: TimeInterval
    let maxPercent: Double
    let userFTP: Double
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
                        y: .value("Power", Double(pwr) / userFTP), 
                        series: .value("Metric", "Power")
                    )
                    .foregroundStyle(Color.yellow)
                }
                
                if let cad = pt.cadence {
                    LineMark(
                        x: .value("Time", timeOffset),
                        y: .value("Cadence", Double(cad) / 100.0), 
                        series: .value("Metric", "Cadence")
                    )
                    .foregroundStyle(Color.blue)
                }
                
                if let hr = pt.hr {
                    LineMark(
                        x: .value("Time", timeOffset),
                        y: .value("HR", Double(hr) / 180.0), 
                        series: .value("Metric", "HR")
                    )
                    .foregroundStyle(Color.red)
                }
            }
        }
        .chartXScale(domain: 0...totalDuration)
        .chartYScale(domain: 0...maxPercent)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .animation(.none, value: recorder.trackpoints.count)
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

#Preview("Session Graph") {
    let recorder = SessionRecorder(settings: SettingsManager())
    
    // Add 1000 points to ensure we have enough duration for labels
    let _ = {
        let now = Date()
        for i in 0..<1000 {
            let pt = Trackpoint(
                time: now.addingTimeInterval(Double(i)),
                hr: 120 + Int(sin(Double(i)/20.0) * 10),
                power: 200 + Int(cos(Double(i)/20.0) * 50)
            )
            recorder.trackpoints.append(pt)
        }
        return true
    }()
    
    VStack(alignment: .leading) {
        Text("Free Ride Graph").font(.headline)
        SessionGraphView(recorder: recorder, userFTP: 200)
            .frame(height: 140)
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
    }
    .padding()
}

#Preview("Workout Graph") {
    let settings = SettingsManager()
    let recorder = SessionRecorder(settings: settings)
    let workout = StructuredWorkout(
        name: "Test intervals",
        description: "Hard work",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.5),
            WorkoutStep(duration: 600, targetPowerPercent: 0.9, endTargetPowerPercent: 1.0),
            WorkoutStep(duration: 300, targetPowerPercent: 0.5)
        ]
    )
    
    // Add some mock points that follow the workout perfectly
    let _ = {
        let now = Date()
        var elapsed: TimeInterval = 0
        for step in workout.steps {
            for i in 0..<Int(step.duration) {
                let intensity = step.powerAt(time: Double(i)) ?? 0.0
                let pt = Trackpoint(
                    time: now.addingTimeInterval(elapsed),
                    hr: 120 + Int(intensity * 40),
                    power: Int(intensity * 250) // Assuming FTP is 250
                )
                recorder.trackpoints.append(pt)
                elapsed += 1
            }
        }
        return true
    }()
    
    VStack(alignment: .leading) {
        Text("Structured Workout Graph").font(.headline)
        WorkoutGraphView(workout: workout, userFTP: 250, elapsedTime: 600, recorder: recorder)
            .frame(height: 140)
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
    }
    .padding()
}
