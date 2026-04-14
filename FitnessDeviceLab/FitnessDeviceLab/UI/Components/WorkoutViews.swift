import SwiftUI
import Charts

struct WorkoutGraphView: View {
    let workout: StructuredWorkout
    let userFTP: Double
    let userLTHR: Double
    var showAxis: Bool = true
    var elapsedTime: TimeInterval? = nil
    var recorder: SessionRecorder? = nil
    var sessionStartTime: Date? = nil
    var scale: Double = 1.0
    
    init(workout: StructuredWorkout, userFTP: Double, userLTHR: Double, showAxis: Bool = true, elapsedTime: TimeInterval? = nil, recorder: SessionRecorder? = nil, sessionStartTime: Date? = nil, scale: Double = 1.0) {
        self.workout = workout
        self.userFTP = userFTP
        self.userLTHR = userLTHR
        self.showAxis = showAxis
        self.elapsedTime = elapsedTime
        self.recorder = recorder
        self.sessionStartTime = sessionStartTime
        self.scale = scale
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if showAxis {
                HStack {
                    Spacer()
                    GraphLegend()
                }
                .padding(.horizontal, 10)
            }
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let totalDuration = workout.totalDuration
                let ftp = userFTP
                let lthr = userLTHR
                let workoutScale = scale
                
                // Calculate max value in absolute units (Watts or BPM)
                let maxTargetValue = workout.steps.map { step in
                    if let hrPct = step.targetHeartRatePercent {
                        return hrPct * Double(lthr) * workoutScale
                    } else {
                        return (step.targetPowerPercent ?? 0.0) * ftp * workoutScale
                    }
                }.max() ?? ftp
                
                let maxActualPower = recorder?.trackpoints.compactMap { $0.power }.map { Double($0) }.max() ?? 0.0
                let maxActualHR = recorder?.trackpoints.compactMap { $0.hr }.map { Double($0) }.max() ?? 0.0
                
                // Final domain max (capped power scaling at 1.5 * FTP if no high target exists)
                let maxPossiblePower = max(maxActualPower, ftp * 1.5)
                let maxValue = max(maxTargetValue, min(maxPossiblePower, max(maxActualPower, maxActualHR))) * 1.1
                
                ZStack(alignment: .bottomLeading) {
                    // Background grid lines and labels
                    if showAxis {
                        let increments: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5]
                        ForEach(increments, id: \.self) { pct in
                            let wattVal = pct * ftp
                            if wattVal < maxValue {
                                let y = height * (1.0 - (wattVal / maxValue))
                                
                                // Grid line
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: width, y: y))
                                }
                                .stroke(Color.secondary.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [2]))
                                
                                // Labels
                                Text("\(Int(wattVal))")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .position(x: 20, y: y - 6)
                                
                                Text("\(Int(wattVal))")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .position(x: width - 20, y: y - 6)
                            }
                        }
                        
                        // Time X-axis
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
                            
                            let isHR = step.targetHeartRatePercent != nil
                            let startVal = isHR ? (step.targetHeartRatePercent! * Double(lthr)) : ((step.targetPowerPercent ?? 0.0) * ftp)
                            let endVal = isHR ? (step.targetHeartRatePercent! * Double(lthr)) : ((step.endTargetPowerPercent ?? step.targetPowerPercent ?? 0.0) * ftp)
                            
                            RampShape(startRelativeHeight: startVal * workoutScale / maxValue,
                                      endRelativeHeight: endVal * workoutScale / maxValue)
                                .fill(color(for: step, scale: workoutScale).opacity(0.3))
                                .frame(width: max(2, stepWidth), height: height)
                                .overlay(alignment: .bottom) {
                                    if stepWidth > 30 {
                                        let avgPercent = (isHR ? step.targetHeartRatePercent! : ((step.targetPowerPercent ?? 0.0) + (step.endTargetPowerPercent ?? step.targetPowerPercent ?? 0.0)) / 2.0) * workoutScale
                                        Text("\(Int(round(avgPercent * 100)))%")
                                            .font(.system(size: 8, weight: .black, design: .monospaced))
                                            .foregroundColor(color(for: step, scale: workoutScale).opacity(0.8))
                                            .padding(.bottom, 2)
                                            .fixedSize()
                                    }
                                }
                        }
                    }
                    
                    // The live data (foreground)
                    if let recorder = recorder {
                        PerformanceChart(
                            recorder: recorder,
                            totalDuration: totalDuration,
                            maxPower: maxValue,
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
    let userLTHR: Double
    var showAxis: Bool = true
    
    var body: some View {
        VStack(spacing: 4) {
            if showAxis {
                HStack {
                    Spacer()
                    GraphLegend()
                }
                .padding(.horizontal, 10)
            }
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                let recordedPoints = Double(recorder.trackpoints.count)
                let totalDuration = max(300, recordedPoints * 1.1)
                let ftp = userFTP

                let maxActualPower = recorder.trackpoints.compactMap { $0.power }.map { Double($0) }.max() ?? 0.0
                let maxActualHR = recorder.trackpoints.compactMap { $0.hr }.map { Double($0) }.max() ?? 0.0
                
                let maxValue = max(ftp * 1.5, max(maxActualPower, maxActualHR)) * 1.1
                
                ZStack(alignment: .bottomLeading) {
                    if showAxis {
                        let increments: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5]
                        ForEach(increments, id: \.self) { pct in
                            let wattVal = pct * ftp
                            if wattVal < maxValue {
                                let y = height * (1.0 - (wattVal / maxValue))
                                
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: width, y: y))
                                }
                                .stroke(Color.secondary.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [2]))
                                
                                Text("\(Int(wattVal))")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .position(x: 20, y: y - 6)
                            }
                        }
                        
                        let timeStep: TimeInterval = totalDuration > 3600 ? 900 : (totalDuration > 1800 ? 600 : 300)
                        ForEach(Array(Swift.stride(from: timeStep, to: totalDuration, by: timeStep)), id: \.self) { t in
                            let x = (CGFloat(t) / CGFloat(totalDuration)) * width
                            Text("\(Int(t/60))m")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.8))
                                .position(x: x, y: height - 6)
                        }
                    }
                    
                    GrowingPerformanceChart(
                        recorder: recorder,
                        totalDuration: totalDuration,
                        maxPower: maxValue
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
            ForEach(downsampledTrackpoints) { pt in
                let index = recorder.trackpoints.firstIndex(where: { $0.id == pt.id }) ?? 0
                let timeOffset = Double(index)
                
                if let pwr = pt.power {
                    LineMark(
                        x: .value("Time", timeOffset),
                        y: .value("Power", min(Double(pwr), 1600)),
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
        .animation(.none, value: recorder.trackpoints.count)
    }
}

struct PerformanceChart: View {
    @Bindable var recorder: SessionRecorder
    let totalDuration: TimeInterval
    let maxPower: Double
    let startTime: Date?
    
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
            ForEach(downsampledTrackpoints) { pt in
                let index = recorder.trackpoints.firstIndex(where: { $0.id == pt.id }) ?? 0
                let timeOffset = Double(index)
                
                if let pwr = pt.power {
                    LineMark(
                        x: .value("Time", timeOffset),
                        y: .value("Power", min(Double(pwr), 1600)),
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
        .animation(.none, value: recorder.trackpoints.count)
    }
}

struct WorkoutRowView: View {
    let workout: StructuredWorkout
    let userFTP: Double
    let userLTHR: Double
    
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
                        
                        if workout.isHybrid {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill").foregroundColor(.yellow)
                                Image(systemName: "heart.fill").foregroundColor(.red)
                                Text("Hybrid")
                            }
                            .imageScale(.small)
                        } else {
                            Label(workout.primaryMetric.rawValue, systemImage: workout.primaryMetric == .power ? "bolt.fill" : "heart.fill")
                                .foregroundColor(workout.primaryMetric == .power ? .yellow : .red)
                                .imageScale(.small)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            WorkoutGraphView(workout: workout, userFTP: userFTP, userLTHR: userLTHR, showAxis: false)
                .frame(height: 50)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Legend Components

struct DFAAlpha1ChartView: View {
    @Bindable var recorder: SessionRecorder
    
    private var downsampledPoints: [Trackpoint] {
        let maxPoints = 300
        let points = recorder.trackpoints
        guard points.count > maxPoints else { return points }
        let stride = points.count / maxPoints
        var result: [Trackpoint] = []
        for i in Swift.stride(from: 0, to: points.count, by: stride) {
            result.append(points[i])
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Chart {
                // Threshold lines
                RuleMark(y: .value("VT1", 0.75))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.green.opacity(0.5))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("VT1 (0.75)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.green)
                    }
                
                RuleMark(y: .value("VT2", 0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.red.opacity(0.5))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("VT2 (0.50)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.red)
                    }
                
                ForEach(downsampledPoints) { pt in
                    if let dfa = pt.dfaAlpha1 {
                        LineMark(
                            x: .value("Time", pt.time),
                            y: .value("DFA a1", dfa)
                        )
                        .foregroundStyle(.purple)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Time", pt.time),
                            y: .value("DFA a1", dfa)
                        )
                        .foregroundStyle(.purple.opacity(0.1))
                    }
                }
            }
            .chartYScale(domain: 0.3...1.5)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0.5, 0.75, 1.0, 1.25]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text(String(format: "%.2f", d))
                                .font(.system(size: 8, design: .monospaced))
                        }
                    }
                }
            }
        }
    }
}

struct GraphLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            LegendItem(label: "Power", icon: "bolt.fill", color: .yellow)
            LegendItem(label: "Cadence", icon: "bicycle", color: .blue)
            LegendItem(label: "HR", icon: "heart.fill", color: .red)
        }
        .font(.system(size: 8, weight: .black))
    }
}

struct LegendItem: View {
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label.uppercased())
                .foregroundColor(.secondary)
        }
    }
}

#Preview("Session Graph") {
    let recorder = SessionRecorder(settings: SettingsManager())
    
    // Add 1000 points
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
        SessionGraphView(recorder: recorder, userFTP: 200, userLTHR: 170)
            .frame(height: 140)
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
    }
    .padding()
}

#Preview("Workout Graph") {
    let workout = StructuredWorkout(
        name: "Threshold Intervals",
        description: "Hard work",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.5),
            WorkoutStep(duration: 600, targetPowerPercent: 0.9, endTargetPowerPercent: 1.0),
            WorkoutStep(duration: 300, targetPowerPercent: 0.5)
        ]
    )
    
    VStack(alignment: .leading) {
        Text("Structured Workout Graph").font(.headline)
        WorkoutGraphView(workout: workout, userFTP: 250, userLTHR: 170)
            .frame(height: 140)
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
    }
    .padding()
}

#Preview("Workout Row") {
    let workout = StructuredWorkout(
        name: "Tabata Sprints",
        description: "20s on, 10s off.",
        steps: [
            WorkoutStep(duration: 300, targetPowerPercent: 0.5),
            WorkoutStep(duration: 20, targetPowerPercent: 1.5),
            WorkoutStep(duration: 10, targetPowerPercent: 0.4)
        ]
    )
    
    List {
        WorkoutRowView(workout: workout, userFTP: 250, userLTHR: 170)
    }
}

struct GenericMetricGraphView: View {
    let field: DataFieldType
    @Bindable var recorder: SessionRecorder
    let userFTP: Double
    let userLTHR: Double
    
    var body: some View {
        Chart {
            ForEach(recorder.trackpoints) { pt in
                if let value = valueForField(pt) {
                    LineMark(
                        x: .value("Time", pt.time),
                        y: .value(field.rawValue, value)
                    )
                    .foregroundStyle(field.color)
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisValueLabel().font(.system(size: 8, design: .monospaced))
            }
        }
    }
    
    private func valueForField(_ pt: Trackpoint) -> Double? {
        switch field {
        case .currentHR: return Double(pt.hr ?? 0)
        case .currentPower: return Double(pt.power ?? 0)
        case .cadence: return Double(pt.cadence ?? 0)
        case .speed: return pt.speed
        default: return nil
        }
    }
}

struct GraphFactoryView: View {
    let type: GraphType
    @Bindable var recorder: SessionRecorder
    let workoutManager: WorkoutSessionManager
    let settings: any SettingsProvider
    
    var body: some View {
        Group {
            switch type {
            case .workout:
                if let workout = workoutManager.selectedWorkout {
                    WorkoutGraphView(
                        workout: workout,
                        userFTP: settings.userFTP,
                        userLTHR: Double(settings.userLTHR),
                        elapsedTime: workoutManager.workoutElapsedTime,
                        recorder: recorder,
                        scale: workoutManager.workoutDifficultyScale
                    )
                } else {
                    SessionGraphView(
                        recorder: recorder,
                        userFTP: settings.userFTP,
                        userLTHR: Double(settings.userLTHR)
                    )
                }
            case .dfaAlpha1:
                DFAAlpha1ChartView(recorder: recorder)
            case .metric(let field):
                GenericMetricGraphView(
                    field: field,
                    recorder: recorder,
                    userFTP: settings.userFTP,
                    userLTHR: Double(settings.userLTHR)
                )
            }
        }
        .padding(8)
    }
}

struct SwipeableGraphContainer: View {
    let graphs: [GraphType]
    @Bindable var recorder: SessionRecorder
    let workoutManager: WorkoutSessionManager
    let settings: any SettingsProvider
    
    @State private var selection = 0
    
    var body: some View {
        VStack(spacing: 4) {
            TabView(selection: $selection) {
                ForEach(0..<graphs.count, id: \.self) { index in
                    GraphFactoryView(
                        type: graphs[index],
                        recorder: recorder,
                        workoutManager: workoutManager,
                        settings: settings
                    )
                    .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .always))
            #endif
            
            if selection < graphs.count {
                Text(graphs[selection].title)
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}
