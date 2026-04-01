import SwiftUI

struct StepPalette: View {
    @Bindable var viewModel: WorkoutEditorViewModel
    
    let templates: [WorkoutStepTemplate] = [
        WorkoutStepTemplate(name: "Warmup", type: .warmup, duration: 600, startPct: 0.5, endPct: 0.7),
        WorkoutStepTemplate(name: "Work", type: .work, duration: 300, startPct: 1.0, endPct: 1.0),
        WorkoutStepTemplate(name: "Recovery", type: .recovery, duration: 120, startPct: 0.5, endPct: 0.5),
        WorkoutStepTemplate(name: "Cooldown", type: .cooldown, duration: 600, startPct: 0.7, endPct: 0.5)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADD BLOCKS")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(templates) { template in
                    PaletteItem(template: template)
                        .onTapGesture {
                            viewModel.addStep(template.toWorkoutStep())
                        }
                        .draggable(TransferableWorkoutStep(step: template.toWorkoutStep()))
                }
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
            id: UUID(), // New ID for each drag/tap
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
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color(for: template.type).opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon(for: template.type))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color(for: template.type))
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(template.name)
                    .font(.system(size: 10, weight: .bold))
                Text(formatDuration(template.duration))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(6)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        return "\(mins)m"
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
