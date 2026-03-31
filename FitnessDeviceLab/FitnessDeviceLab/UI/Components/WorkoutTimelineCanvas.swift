import SwiftUI
import UniformTypeIdentifiers

struct WorkoutTimelineCanvas: View {
    @Binding var steps: [WorkoutStep]
    @Binding var selectedStepID: UUID?
    @Binding var selectedStepIDs: Set<UUID>
    
    @State private var lassoRect: CGRect?
    @State private var stepFrames: [UUID: CGRect] = [:]
    
    // Drop tracking
    @State private var insertionIndex: Int? = nil
    @State private var isTargeted = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // The Grid Background (Captures the Lasso Gesture)
                TimelineGrid()
                    .frame(minWidth: max(400, totalWidth), minHeight: 140)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
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
                
                HStack(alignment: .bottom, spacing: 0) {
                    if steps.isEmpty {
                        EmptyTimelinePlaceholder()
                            .dropDestination(for: TransferableWorkoutStep.self) { items, _ in
                                handleDrop(items: items, at: 0)
                                return true
                            }
                    } else {
                        // Initial drop zone
                        dropGap(at: 0)
                        
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
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
                                .draggable(dragValue(for: step))
                            
                            // Gap after each block
                            dropGap(at: index + 1)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Lasso Box
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
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func dropGap(at index: Int) -> some View {
        ZStack {
            // Invisible but wide hit area
            Color.clear
                .frame(width: 20, height: 120)
                .contentShape(Rectangle())
                .dropDestination(for: TransferableWorkoutStep.self) { items, _ in
                    handleDrop(items: items, at: index)
                    return true
                } isTargeted: { targeted in
                    if targeted {
                        insertionIndex = index
                    } else if insertionIndex == index {
                        insertionIndex = nil
                    }
                }
            
            // Visual Indicator
            if insertionIndex == index {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 2, height: 100)
                    .shadow(color: .blue.opacity(0.5), radius: 4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: insertionIndex)
    }
    
    // MARK: - Logic
    
    private var totalWidth: CGFloat {
        steps.reduce(0) { $0 + max(40, CGFloat($1.duration / 5)) } + CGFloat(steps.count * 20) + 40
    }
    
    private func dragValue(for step: WorkoutStep) -> TransferableWorkoutStep {
        if selectedStepIDs.contains(step.id) {
            let selectedSteps = steps.filter { selectedStepIDs.contains($0.id) }
            return TransferableWorkoutStep(steps: selectedSteps)
        } else {
            return TransferableWorkoutStep(step: step)
        }
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
    
    private func handleDrop(items: [TransferableWorkoutStep], at index: Int) {
        guard let droppedSteps = items.first?.steps else { return }
        let existingIDs = Set(steps.map { $0.id })
        let itemsToReorder = droppedSteps.filter { existingIDs.contains($0.id) }
        let itemsToInsert = droppedSteps.filter { !existingIDs.contains($0.id) }
        
        withAnimation(.spring()) {
            if !itemsToReorder.isEmpty {
                let fromIndices = IndexSet(itemsToReorder.compactMap { item in steps.firstIndex(where: { $0.id == item.id }) })
                steps.move(fromOffsets: fromIndices, toOffset: index)
            } else if !itemsToInsert.isEmpty {
                steps.insert(contentsOf: itemsToInsert, at: min(index, steps.count))
            }
            insertionIndex = nil
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
    static let maxDisplayIntensity: Double = 2.5
    
    var body: some View {
        let width = max(40, CGFloat(step.duration / 5))
        let startPct = (step.targetPowerPercent ?? step.targetHeartRatePercent ?? 0.0) / Self.maxDisplayIntensity
        let endPct = (step.endTargetPowerPercent ?? step.targetHeartRatePercent ?? 0.0) / Self.maxDisplayIntensity
        
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                RampShape(startRelativeHeight: startPct, endRelativeHeight: endPct)
                    .fill(step.currentZone.color.opacity(0.3))
                    .overlay(
                        RampShape(startRelativeHeight: startPct, endRelativeHeight: endPct)
                            .stroke(isSelected ? Color.blue : step.currentZone.color, lineWidth: isSelected ? 4 : 1)
                    )
                
                Text(formatDuration(step.duration))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
            }
            .frame(width: width, height: 100)
            
            let avgPercent = ((step.targetPowerPercent ?? step.targetHeartRatePercent ?? 0.0) + (step.endTargetPowerPercent ?? step.targetHeartRatePercent ?? 0.0)) / 2.0
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
