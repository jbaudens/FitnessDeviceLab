import SwiftUI

public struct WorkoutGraphView: View {
    public let workout: StructuredWorkout
    public var showAxis: Bool = true
    public var elapsedTime: TimeInterval? = nil
    
    public init(workout: StructuredWorkout, showAxis: Bool = true, elapsedTime: TimeInterval? = nil) {
        self.workout = workout
        self.showAxis = showAxis
        self.elapsedTime = elapsedTime
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let totalDuration = workout.totalDuration
                
                // Max height is based on the highest interval, at least 100%
                let maxPercent = max(1.0, workout.steps.map { $0.targetPowerPercent }.max() ?? 1.0) * 1.1
                
                ZStack(alignment: .bottomLeading) {
                    // Background grid lines (50%, 100%)
                    if showAxis {
                        Path { path in
                            let y50 = height * (1.0 - (0.5 / maxPercent))
                            let y100 = height * (1.0 - (1.0 / maxPercent))
                            
                            path.move(to: CGPoint(x: 0, y: y50))
                            path.addLine(to: CGPoint(x: width, y: y50))
                            
                            path.move(to: CGPoint(x: 0, y: y100))
                            path.addLine(to: CGPoint(x: width, y: y100))
                        }
                        .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                    
                    // The bars
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(workout.steps) { step in
                            let stepWidth = (CGFloat(step.duration) / CGFloat(totalDuration)) * (width - CGFloat(workout.steps.count))
                            let stepHeight = (CGFloat(step.targetPowerPercent) / CGFloat(maxPercent)) * height
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color(for: step))
                                .frame(width: max(2, stepWidth), height: max(4, stepHeight))
                        }
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
    
    private func color(for step: WorkoutStep) -> Color {
        if step.type == .recovery || step.type == .warmup || step.type == .cooldown {
            return WorkoutZone.forIntensity(step.targetPowerPercent).color.opacity(0.6)
        }
        return WorkoutZone.forIntensity(step.targetPowerPercent).color
    }
}

public struct WorkoutRowView: View {
    public let workout: StructuredWorkout
    
    public var body: some View {
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
                    
                    Text("\(Int(workout.totalDuration / 60)) min • IF \(String(format: "%.2f", workout.averageIntensity))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            WorkoutGraphView(workout: workout, showAxis: false)
                .frame(height: 40)
        }
        .padding(.vertical, 8)
    }
}
