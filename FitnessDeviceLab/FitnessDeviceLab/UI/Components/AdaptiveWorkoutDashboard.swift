import SwiftUI

struct AdaptiveWorkoutDashboard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var viewModel: WorkoutPlayerViewModel
    let settings: any SettingsProvider
    
    var body: some View {
        GeometryReader { geo in
            if geo.size.width > 800 && horizontalSizeClass != .compact {
                // Landscape Lab Mode
                HStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            if viewModel.workoutManager.recorderA.hasAnySensor && viewModel.workoutManager.recorderB.hasAnySensor {
                                comparisonHeader
                                    .padding(.top, 8)
                            }
                            
                            ForEach(viewModel.workoutManager.activeProfile.pages) { page in
                                HStack(spacing: 0) {
                                    if viewModel.workoutManager.recorderA.hasAnySensor {
                                        sensorSetColumn(title: "SET A", color: .blue, recorder: viewModel.workoutManager.recorderA, fields: page.fields)
                                    }
                                    
                                    if viewModel.workoutManager.recorderB.hasAnySensor {
                                        sensorSetColumn(title: "SET B", color: .purple, recorder: viewModel.workoutManager.recorderB, fields: page.fields)
                                    }
                                }
                                
                                if page.id != viewModel.workoutManager.activeProfile.pages.last?.id {
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    Divider()
                    
                    // Laps History in a sidebar-like column for Lab Mode
                    LapsHistoryView(workoutManager: viewModel.workoutManager, settings: viewModel.settings)
                        .frame(width: 300)
                        .background(Color.secondary.opacity(0.05))
                }
            } else {
                // Portrait/Mobile Mode (Existing layout)
                TabView {
                    // Data Pages
                    ForEach(viewModel.workoutManager.activeProfile.pages) { page in
                        ScrollView {
                            VStack(spacing: 32) {
                                if viewModel.workoutManager.recorderA.hasAnySensor {
                                    sensorSetSection(title: "SET A", color: Color.blue, recorder: viewModel.workoutManager.recorderA, fields: page.fields)
                                }
                                
                                if viewModel.workoutManager.recorderA.hasAnySensor && viewModel.workoutManager.recorderB.hasAnySensor {
                                    Divider().padding(.horizontal)
                                }
                                
                                if viewModel.workoutManager.recorderB.hasAnySensor {
                                    sensorSetSection(title: "SET B", color: Color.purple, recorder: viewModel.workoutManager.recorderB, fields: page.fields)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    
                    // Laps View
                    LapsHistoryView(workoutManager: viewModel.workoutManager, settings: viewModel.settings)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .always))
                #endif
            }
        }
    }
    
    private var comparisonHeader: some View {
        HStack(spacing: 20) {
            Spacer()
            
            // Power Delta Badge
            let pwrA = Double(viewModel.workoutManager.recorderA.powerSource?.cyclingPower ?? 0)
            let pwrB = Double(viewModel.workoutManager.recorderB.powerSource?.cyclingPower ?? 0)
            let pwrDelta = pwrA - pwrB
            let pwrPct = pwrB > 0 ? (pwrDelta / pwrB) * 100 : 0
            
            comparisonBadge(
                label: "PWR Δ",
                value: "\(Int(abs(pwrDelta)))W",
                percent: String(format: "%.1f%%", abs(pwrPct)),
                color: pwrColor(percent: pwrPct)
            )
            
            // HR Delta Badge
            let hrA = Double(viewModel.workoutManager.recorderA.hrSource?.heartRate ?? 0)
            let hrB = Double(viewModel.workoutManager.recorderB.hrSource?.heartRate ?? 0)
            let hrDelta = hrA - hrB
            
            comparisonBadge(
                label: "HR Δ",
                value: "\(Int(abs(hrDelta)))",
                percent: "BPM",
                color: hrColor(delta: hrDelta)
            )
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func comparisonBadge(label: String, value: String, percent: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                Text(percent)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func pwrColor(percent: Double) -> Color {
        let absPct = abs(percent)
        if absPct < 3.0 { return .green }
        if absPct < 7.0 { return .orange }
        return .red
    }
    
    private func hrColor(delta: Double) -> Color {
        let absDelta = abs(delta)
        if absDelta < 3.0 { return .green }
        if absDelta < 6.0 { return .orange }
        return .red
    }
    
    private func sensorSetColumn(title: String, color: Color, recorder: SessionRecorder, fields: [DataFieldType]) -> some View {
        VStack(spacing: 0) {
            // Re-use sensorSetSection logic but optimized for column
            sensorSetSection(title: title, color: color, recorder: recorder, fields: fields)
        }
        .frame(maxWidth: .infinity)
    }

    private func sensorSetSection(title: String, color: Color, recorder: SessionRecorder, fields: [DataFieldType]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: title == "SET A" ? "1.circle.fill" : "2.circle.fill")
                Spacer()
                Text(viewModel.deviceNames(recorder: recorder))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .font(.caption)
            .fontWeight(.black)
            .foregroundColor(color)
            .padding(.horizontal)
            
            if viewModel.workoutManager.activeProfile.name == "DFA Analysis" {
                DFAAlpha1ChartView(recorder: recorder)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            if let workout = viewModel.workoutManager.selectedWorkout {
                WorkoutGraphView(
                    workout: workout,
                    userFTP: viewModel.settings.userFTP,
                    elapsedTime: viewModel.workoutManager.workoutElapsedTime,
                    recorder: recorder,
                    scale: viewModel.workoutManager.workoutDifficultyScale
                )
                .frame(height: 140)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                SessionGraphView(
                    recorder: recorder,
                    userFTP: viewModel.settings.userFTP
                )
                .frame(height: 140)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            DataFieldGrid(
                engine: recorder.engine,
                fields: fields,
                settings: viewModel.settings
            )
            .padding(.horizontal)
        }
    }
}
