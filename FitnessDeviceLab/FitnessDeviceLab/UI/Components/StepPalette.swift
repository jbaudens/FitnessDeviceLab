import SwiftUI

struct StepPalette: View {
    let templates: [WorkoutStepTemplate] = [
        WorkoutStepTemplate(name: "Warmup", type: .warmup, duration: 600, startPct: 0.5, endPct: 0.7),
        WorkoutStepTemplate(name: "Work", type: .work, duration: 300, startPct: 1.0, endPct: 1.0),
        WorkoutStepTemplate(name: "Recovery", type: .recovery, duration: 120, startPct: 0.5, endPct: 0.5),
        WorkoutStepTemplate(name: "Cooldown", type: .cooldown, duration: 600, startPct: 0.7, endPct: 0.5)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STEP PALETTE")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(templates) { template in
                        PaletteItem(template: template)
                            .draggable(TransferableWorkoutStep(step: template.toWorkoutStep()))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
    }
}

struct WorkoutStepTemplate: Identifiable {
    let id = UUID()
    let name: String
    let type: WorkoutStepType
    let duration: TimeInterval
    let startPct: Double
    let endPct: Double
    
    func toWorkoutStep() -> WorkoutStep {
        WorkoutStep(
            id: UUID(), // New ID for each drag
            duration: duration,
            targetPowerPercent: startPct,
            endTargetPowerPercent: endPct,
            type: type
        )
    }
}

struct PaletteItem: View {
    let template: WorkoutStepTemplate
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color(for: template.type).opacity(0.2))
                    .frame(width: 80, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color(for: template.type), lineWidth: 1)
                    )
                
                Image(systemName: icon(for: template.type))
                    .foregroundColor(color(for: template.type))
            }
            
            Text(template.name.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
        }
    }
    
    private func color(for type: WorkoutStepType) -> Color {
        switch type {
        case .warmup: return .blue
        case .work: return .red
        case .recovery: return .green
        case .cooldown: return .gray
        }
    }
    
    private func icon(for type: WorkoutStepType) -> String {
        switch type {
        case .warmup: return "flame.fill"
        case .work: return "bolt.fill"
        case .recovery: return "heart.fill"
        case .cooldown: return "snowflake"
        }
    }
}
