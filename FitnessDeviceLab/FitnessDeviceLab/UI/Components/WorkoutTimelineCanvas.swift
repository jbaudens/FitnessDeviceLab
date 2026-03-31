import SwiftUI
import UniformTypeIdentifiers

struct WorkoutTimelineCanvas: View {
    @Binding var steps: [WorkoutStep]
    @Binding var selectedStepID: UUID?
    @Binding var selectedStepIDs: Set<UUID>
    
    @State private var lassoRect: CGRect?
    @State private var stepFrames: [UUID: CGRect] = [:]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // The Grid Background (Captures the Lasso Gesture)
                TimelineGrid()
                    .frame(minWidth: max(400, totalWidth), minHeight: 140)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                let start = value.startLocation
                                let current = value.location
                                lassoRect = CGRect(
                                    x: min(start.x, current.x),
                                    y: min(start.y, current.y),
                                    width: abs(current.x - start.x),
                                    height: abs(current.y - start.y)
                                )
                                updateSelection()
                            }
                            .onEnded { _ in
                                lassoRect = nil
                            }
                    )
                
                HStack(alignment: .bottom, spacing: 4) {
                    if steps.isEmpty {
                        EmptyTimelinePlaceholder()
                    } else {
                        ForEach(steps) { step in
                            WorkoutStepBlock(step: step, isSelected: selectedStepIDs.contains(step.id))
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(
                                            key: StepFramePreferenceKey.self,
                                            value: [step.id: geo.frame(in: .named("TimelineCanvas"))]
                                        )
                                    }
                                )
                                .onTapGesture {
                                    selectedStepID = step.id
                                    selectedStepIDs = [step.id]
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
                .padding(.bottom, 20)
                
                if let rect = lassoRect {
                    Rectangle()
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .background(Color.blue.opacity(0.1))
                        .frame(width: rect.width, height: rect.height)
                        .offset(x: rect.origin.x, y: rect.origin.y)
                }
            }
            .coordinateSpace(name: "TimelineCanvas")
            .onPreferenceChange(StepFramePreferenceKey.self) { frames in
                self.stepFrames = frames
            }
        }
        .dropDestination(for: TransferableWorkoutStep.self) { items, location in
            // Handle drops from palette onto the empty canvas
            if let tStep = items.first, !steps.contains(where: { $0.id == tStep.step.id }) {
                withAnimation {
                    steps.append(tStep.step)
                }
                return true
            }
            return false
        }
    }
    
    private var totalWidth: CGFloat {
        steps.reduce(0) { $0 + max(40, CGFloat($1.duration / 5)) } + CGFloat(steps.count * 4) + 40
    }
    
    private func updateSelection() {
        guard let lasso = lassoRect else { return }
        let selected = stepFrames.filter { $1.intersects(lasso) }.map { $0.key }
        if !selected.isEmpty {
            selectedStepIDs = Set(selected)
            if selected.count == 1 {
                selectedStepID = selected.first
            } else {
                selectedStepID = nil
            }
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

struct StepFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
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
                            .stroke(isSelected ? Color.blue : step.currentZone.color, lineWidth: isSelected ? 4 : 1)
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
            Image(systemName: "plus.app")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Tap or Drag steps here")
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
