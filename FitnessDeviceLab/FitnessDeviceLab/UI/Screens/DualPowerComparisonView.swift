import SwiftUI
import Charts

struct DualPowerComparisonView: View {
    let recorderA: SessionRecorder
    let recorderB: SessionRecorder
    
    @State private var comparisonPoints: [ComparisonPoint] = []
    @State private var summary: ComparisonSummary?
    @State private var selectedTab: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Analysis Mode", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Intervals").tag(1)
                    Text("Drift & Bias").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.systemBackground)
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let summary {
                            switch selectedTab {
                            case 0:
                                overviewTab(summary: summary)
                            case 1:
                                intervalsTab(summary: summary)
                            case 2:
                                driftTab(summary: summary)
                            default:
                                EmptyView()
                            }
                        } else {
                            ContentUnavailableView("Analyzing...", systemImage: "timer")
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("Dual Power Lab")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .adaptiveTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                generateComparison()
            }
        }
    }
    
    private func generateComparison() {
        let points = PowerComparisonEngine.alignAndCompare(
            pointsA: recorderA.trackpoints,
            pointsB: recorderB.trackpoints
        )
        self.comparisonPoints = points
        self.summary = PowerComparisonEngine.summarize(points: points)
    }
    
    @ViewBuilder
    private func overviewTab(summary: ComparisonSummary) -> some View {
        VStack(spacing: 32) {
            SummaryDashboard(summary: summary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("POWER OVERLAY")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                PowerOverlayChart(points: comparisonPoints)
                    .frame(height: 400)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("POWER DELTA (A - B)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                DeltaChart(points: comparisonPoints)
                    .frame(height: 250)
                    .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private func intervalsTab(summary: ComparisonSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DETECTED WORK INTERVALS")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if summary.detectedIntervals.isEmpty {
                ContentUnavailableView("No Intervals Detected", systemImage: "waveform.path.ecg", description: Text("No sustained power efforts (>100w) were identified."))
            } else {
                ForEach(summary.detectedIntervals) { interval in
                    IntervalRow(interval: interval)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private func driftTab(summary: ComparisonSummary) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Drift Card
            VStack(alignment: .leading, spacing: 12) {
                Text("THERMAL / TEMPORAL DRIFT")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(summary.estimatedDrift != nil ? String(format: "%+.1f w/hr", summary.estimatedDrift!) : "N/A")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(abs(summary.estimatedDrift ?? 0) < 5 ? .green : .orange)
                        Text("Estimated drift rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "thermometer.medium")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding()
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Bias per Intensity Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("ACCURACY BY INTENSITY")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.secondary)
                
                Chart {
                    ForEach(summary.detectedIntervals) { interval in
                        BarMark(
                            x: .value("Intensity", "\(interval.intensity)w"),
                            y: .value("Delta %", interval.percentDelta)
                        )
                        .foregroundStyle(interval.percentDelta >= 0 ? Color.green : Color.red)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(12)
                
                Text("Shows the percentage difference (A vs B) for each detected work set.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }
    
    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

private struct IntervalRow: View {
    let interval: DetectedInterval
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(interval.duration))s Interval")
                    .font(.headline)
                Text("Start: \(formatElapsed(interval.startSeconds)) | Target: \(interval.intensity)w")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text(String(format: "%+.1f w", interval.delta))
                        .fontWeight(.bold)
                    Text("(\(String(format: "%+.1f%%", interval.percentDelta)))")
                }
                .foregroundColor(abs(interval.percentDelta) < 2 ? .green : (abs(interval.percentDelta) < 5 ? .orange : .red))
                .font(.system(.subheadline, design: .monospaced))
                
                Text("A:\(Int(interval.avgPowerA))w | B:\(Int(interval.avgPowerB))w")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

private struct SummaryDashboard: View {
    let summary: ComparisonSummary
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                MetricCard(title: "AVG POWER A", value: String(format: "%.0f", summary.avgPowerA), unit: "w", color: .blue)
                MetricCard(title: "AVG POWER B", value: String(format: "%.0f", summary.avgPowerB), unit: "w", color: .purple)
            }
            
            HStack(spacing: 12) {
                MetricCard(title: "AVG DELTA", value: String(format: "%.1f", summary.avgDelta), unit: "w", color: .orange)
                MetricCard(title: "DIVERGENCE", value: "\(summary.divergencePoints)", unit: "pts", color: .red)
            }
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
}

private struct PowerOverlayChart: View {
    let points: [ComparisonPoint]
    
    var body: some View {
        Chart {
            ForEach(points) { point in
                if let pA = point.powerA {
                    LineMark(
                        x: .value("Time", point.elapsedSeconds),
                        y: .value("Power A", pA),
                        series: .value("Series", "A")
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                }
                
                if let pB = point.powerB {
                    LineMark(
                        x: .value("Time", point.elapsedSeconds),
                        y: .value("Power B", pB),
                        series: .value("Series", "B")
                    )
                    .foregroundStyle(.purple)
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 300)) { value in
                AxisGridLine()
                AxisTick()
                if let seconds = value.as(Double.self) {
                    AxisValueLabel {
                        Text(formatElapsed(seconds))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

private struct DeltaChart: View {
    let points: [ComparisonPoint]
    
    var body: some View {
        Chart {
            RuleMark(y: .value("Zero", 0))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(.secondary)
            
            ForEach(points) { point in
                if let delta = point.delta {
                    AreaMark(
                        x: .value("Time", point.elapsedSeconds),
                        y: .value("Delta", delta)
                    )
                    .foregroundStyle(delta >= 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                    .interpolationMethod(.linear)
                    
                    LineMark(
                        x: .value("Time", point.elapsedSeconds),
                        y: .value("Delta", delta)
                    )
                    .foregroundStyle(delta >= 0 ? Color.green : Color.red)
                    .interpolationMethod(.linear)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 300)) { value in
                AxisGridLine()
                AxisTick()
                if let seconds = value.as(Double.self) {
                    AxisValueLabel {
                        Text(formatElapsed(seconds))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    let settings = SettingsManager()
    let recA = SessionRecorder(settings: settings)
    let recB = SessionRecorder(settings: settings)
    
    let now = Date()
    var pointsA: [Trackpoint] = []
    var pointsB: [Trackpoint] = []
    
    for i in 0..<900 {
        let time = now.addingTimeInterval(TimeInterval(i))
        let progress = Double(i) / 900.0
        
        var basePower: Double = 120.0
        // Recovery segments in between
        if i > 100 && i < 250 { basePower = 200.0 }
        else if i > 250 && i < 350 { basePower = 100.0 } // Recovery
        else if i > 350 && i < 500 { basePower = 350.0 }
        else if i > 500 && i < 600 { basePower = 100.0 } // Recovery
        else if i > 600 && i < 750 { basePower = 450.0 }
        else if i > 750 { basePower = 100.0 } // Recovery
        
        let pA = basePower * 1.01 + Double.random(in: -2...2)
        pointsA.append(Trackpoint(time: time, power: Int(max(0, pA))))
        
        let drift = progress * -8.0
        let scalingError = (basePower > 300) ? 0.96 : 0.98
        let pB = basePower * scalingError + drift + Double.random(in: -3...3)
        pointsB.append(Trackpoint(time: time, power: Int(max(0, pB))))
    }
    
    recA.trackpoints = pointsA
    recB.trackpoints = pointsB
    
    return DualPowerComparisonView(recorderA: recA, recorderB: recB)
}
