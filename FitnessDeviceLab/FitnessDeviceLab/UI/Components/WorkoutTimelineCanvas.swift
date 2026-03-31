import SwiftUI
import UniformTypeIdentifiers

struct WorkoutTimelineCanvas: View {
    @Binding var steps: [WorkoutStep]
    @Binding var selectedStepID: UUID?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 4) {
                if steps.isEmpty {
                    EmptyTimelinePlaceholder()
                } else {
                    ForEach(steps) { step in
                        WorkoutStepBlock(step: step, isSelected: selectedStepID == step.id)
                            .onTapGesture {
                                selectedStepID = step.id
                            }
                            .draggable(TransferableWorkoutStep(step: step))
                            .dropDestination(for: TransferableWorkoutStep.self) { items, location in
                                handleReorder(item: items.first?.step, targetStep: step)
                                return true
                            }
                    }
                }
            }
            .padding(.horizontal)
            .frame(minWidth: 400, minHeight: 120)
            .background(TimelineGrid())
        }
        .dropDestination(for: TransferableWorkoutStep.self) { items, location in
            if let tStep = items.first, !steps.contains(where: { $0.id == tStep.step.id }) {
                steps.append(tStep.step)
                return true
            }
            return false
        }
    }
    
    private func handleReorder(item: WorkoutStep?, targetStep: WorkoutStep) {
        guard let item = item,
              let fromIndex = steps.firstIndex(where: { $0.id == item.id }),
              let toIndex = steps.firstIndex(where: { $0.id == targetStep.id }),
              fromIndex != toIndex else { return }
        
        withAnimation {
            steps.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
}

struct WorkoutStepBlock: View {
    let step: WorkoutStep
    let isSelected: Bool
    
    var body: some View {
        let width = max(40, CGFloat(step.duration / 5)) // Scale: 5s = 1pt
        let startPct = step.targetPowerPercent ?? step.targetHeartRatePercent ?? 0.0
        let endPct = step.endTargetPowerPercent ?? step.targetHeartRatePercent ?? 0.0
        
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                // Background Ramp/Block
                RampShape(startRelativeHeight: startPct, endRelativeHeight: endPct)
                    .fill(step.currentZone.color.opacity(0.3))
                    .overlay(
                        RampShape(startRelativeHeight: startPct, endRelativeHeight: endPct)
                            .stroke(step.currentZone.color, lineWidth: isSelected ? 3 : 1)
                    )
                
                // Duration Label
                Text(formatDuration(step.duration))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            .frame(width: width, height: 100)
            
            // Intensity Label
            let avgPercent = (startPct + endPct) / 2.0
            Text("\(Int(round(avgPercent * 100)))%")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(step.currentZone.color)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        if mins > 0 {
            return "\(mins)m\(secs > 0 ? "\(secs)s" : "")"
        } else {
            return "\(secs)s"
        }
    }
}

struct EmptyTimelinePlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "plus.square.dashed")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Drag steps here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
    }
}

struct TimelineGrid: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 20
                for x in stride(from: 0, to: geo.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, to: geo.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.secondary.opacity(0.05), lineWidth: 1)
        }
    }
}
