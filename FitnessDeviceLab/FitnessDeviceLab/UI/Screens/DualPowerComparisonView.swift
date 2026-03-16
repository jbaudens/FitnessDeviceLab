import SwiftUI
import Charts

struct DualPowerComparisonView: View {
    let recorderA: SessionRecorder
    let recorderB: SessionRecorder
    
    @State private var comparisonPoints: [ComparisonPoint] = []
    @State private var summary: ComparisonSummary?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let summary {
                        SummaryDashboard(summary: summary)
                            .padding(.horizontal)
                    }
                    
                    if !comparisonPoints.isEmpty {
                        PowerOverlayChart(points: comparisonPoints)
                            .frame(height: 300)
                            .padding(.horizontal)
                        
                        DeltaChart(points: comparisonPoints)
                            .frame(height: 200)
                            .padding(.horizontal)
                    } else {
                        ContentUnavailableView("No Power Data", systemImage: "bolt.slash.fill", description: Text("Both recorders must have power data to generate a comparison."))
                    }
                }
                .padding(.vertical)
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Divergence points are samples where the delta is greater than 5% between sensors.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        VStack(alignment: .leading) {
            Text("POWER OVERLAY")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(points) { point in
                    if let pA = point.powerA {
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Power A", pA),
                            series: .value("Series", "A")
                        )
                        .foregroundStyle(.blue)
                    }
                    
                    if let pB = point.powerB {
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Power B", pB),
                            series: .value("Series", "B")
                        )
                        .foregroundStyle(.purple)
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
    }
}

private struct DeltaChart: View {
    let points: [ComparisonPoint]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("POWER DELTA (A - B)")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
            
            Chart {
                RuleMark(y: .value("Zero", 0))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(.secondary)
                
                ForEach(points) { point in
                    if let delta = point.delta {
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Delta", delta)
                        )
                        .foregroundStyle(delta >= 0 ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                        
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Delta", delta)
                        )
                        .foregroundStyle(delta >= 0 ? Color.green : Color.red)
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
    }
}
