import SwiftUI

struct SessionSummaryCard: View {
    let files: [URL]
    let engine: DataFieldEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SESSION SUMMARY")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(.green)
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
            }
            
            let m = engine.calculatedMetrics
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                GridRow {
                    SummaryMetric(label: "AVG POWER", value: "\(Int(round(m.standard.avgPower ?? 0)))W")
                    SummaryMetric(label: "NP", value: "\(Int(round(m.standard.normalizedPower ?? 0)))W")
                }
                GridRow {
                    SummaryMetric(label: "IF", value: String(format: "%.2f", m.standard.intensityFactor ?? 0))
                    SummaryMetric(label: "TSS", value: "\(Int(round(m.standard.tss ?? 0)))")
                }
                GridRow {
                    SummaryMetric(label: "AVG HR", value: "\(Int(round(m.hr.avg ?? 0))) BPM")
                    SummaryMetric(label: "MAX HR", value: "\(Int(round(Double(m.hr.max ?? 0)))) BPM")
                }
            }
            
            ShareLink(items: files) {
                Label("Export Session (.TCX & .FIT)", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SummaryMetric: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
        }
    }
}
