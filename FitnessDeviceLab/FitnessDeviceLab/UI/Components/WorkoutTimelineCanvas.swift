import SwiftUI
import UniformTypeIdentifiers

struct WorkoutTimelineCanvas: View {
    @Binding var steps: [WorkoutStep]
    @Binding var selectedStepID: UUID?
    @Binding var selectedStepIDs: Set<UUID>
    
    @State private var lassoRect: CGRect?
    @State private var stepFrames: [UUID: CGRect] = [:]
    
    // Scroll tracking for macOS manual slider
    @State private var scrollOffset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    // Drop tracking
    @State private var insertionIndex: Int? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        // 1. Grid & Interaction Background
                        TimelineGrid()
                            .frame(minWidth: max(containerWidth, totalWidth), minHeight: 140)
                            .background(Color.primary.opacity(0.001))
                            .gesture(selectionGesture)
                        
                        // 2. The Content
                        HStack(alignment: .bottom, spacing: 0) {
                            if steps.isEmpty {
                                EmptyTimelinePlaceholder()
                                    .dropDestination(for: TransferableWorkoutStep.self) { items, _ in
                                        handleDrop(items: items, at: 0)
                                        return true
                                    }
                            } else {
                                dropGap(at: 0)
                                
                                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                                    WorkoutStepBlock(step: step, isSelected: selectedStepIDs.contains(step.id))
                                        .id(step.id) // Used for ScrollViewProxy
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
                                    
                                    dropGap(at: index + 1)
                                }
                            }
                        }
                        .padding(.horizontal, 100)
                        .padding(.bottom, 20)
                        
                        // 3. Lasso Box
                        if let rect = lassoRect {
                            Rectangle()
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .background(Color.blue.opacity(0.1))
                                .frame(width: rect.width, height: rect.height)
                                .offset(x: rect.origin.x, y: rect.origin.y)
                                .allowsHitTesting(false)
                        }
                    }
                    .coordinateSpace(name: "TimelineCanvas")
                    .onPreferenceChange(StepFramePreferenceKey.self) { frames in
                        self.stepFrames = frames
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear { containerWidth = geo.size.width }
                            .onChange(of: geo.size.width) { _, newValue in containerWidth = newValue }
                    }
                )
                
                #if os(macOS)
                // Manual Scroll Controller for macOS (Always Visible)
                if totalWidth > containerWidth {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left.and.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $scrollOffset, in: 0...1) { _ in
                            updateScroll(proxy: proxy)
                        }
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.secondarySystemGroupedBackground)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                #endif
            }
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func dropGap(at index: Int) -> some View {
        ZStack {
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
            
            if insertionIndex == index {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 2, height: 100)
                    .shadow(color: .blue.opacity(0.5), radius: 4)
            }
        }
        .animation(.spring(), value: insertionIndex)
    }
    
    // MARK: - Logic
    
    private var totalWidth: CGFloat {
        steps.reduce(0) { $0 + max(40, CGFloat($1.duration / 5)) } + CGFloat(steps.count * 20) + 240
    }
    
    private func updateScroll(proxy: ScrollViewProxy) {
        guard !steps.isEmpty else { return }
        // Simple heuristic: map slider 0...1 to step indices
        let index = Int(Double(steps.count - 1) * scrollOffset)
        withAnimation {
            proxy.scrollTo(steps[index].id, anchor: .center)
        }
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
                let itemsWithNewIDs = itemsToInsert.map { item in
                    WorkoutStep(
                        id: UUID(), 
                        duration: item.duration,
                        targetPowerPercent: item.targetPowerPercent,
                        endTargetPowerPercent: item.endTargetPowerPercent,
                        targetHeartRatePercent: item.targetHeartRatePercent,
                        type: item.type,
                        targetCadence: item.targetCadence
                    )
                }
                steps.insert(contentsOf: itemsWithNewIDs, at: min(index, steps.count))
            }
            insertionIndex = nil
        }
    }
    
    private var selectionGesture: some Gesture {
        #if os(macOS)
        // On macOS, a standard DragGesture with a higher priority
        return DragGesture(minimumDistance: 10)
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
        #else
        // On iPad/iOS, require long-press to distinguish from scroll
        return LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .second(true, let drag):
                    guard let drag = drag else { return }
                    let start = drag.startLocation
                    let current = drag.location
                    lassoRect = CGRect(
                        x: min(start.x, current.x),
                        y: min(start.y, current.y),
                        width: abs(current.x - start.x),
                        height: abs(current.y - start.y)
                    )
                    updateSelection()
                default:
                    break
                }
            }
            .onEnded { _ in
                lassoRect = nil
            }
        #endif
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
