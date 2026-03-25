import SwiftUI

struct AdaptiveWorkoutDashboard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var viewModel: WorkoutPlayerViewModel
    let settings: SettingsManager
    
    var body: some View {
        GeometryReader { geo in
            if geo.size.width > 800 && horizontalSizeClass != .compact {
                // Landscape Lab Mode
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        sensorSetColumn(title: "SET A", color: .blue, recorder: viewModel.workoutManager.recorderA)
                        varianceColumn
                        sensorSetColumn(title: "SET B", color: .purple, recorder: viewModel.workoutManager.recorderB)
                    }
                    .padding(.top)
                }
            } else {
                // Portrait/Mobile Mode (Existing layout)
                TabView {
                    // Data Pages
                    ForEach(viewModel.workoutManager.activeProfile.pages) { page in
                        ScrollView {
                            VStack(spacing: 32) {
                                sensorSetSection(title: "SET A", color: Color.blue, recorder: viewModel.workoutManager.recorderA, fields: page.fields)
                                
                                Divider().padding(.horizontal)
                                
                                sensorSetSection(title: "SET B", color: Color.purple, recorder: viewModel.workoutManager.recorderB, fields: page.fields)
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
    
    private var varianceColumn: some View {
        VStack(spacing: 20) {
            Text("DELTA")
                .font(.caption)
                .fontWeight(.black)
                .foregroundColor(.secondary)
            
            let pwrA = Double(viewModel.workoutManager.recorderA.powerSource?.cyclingPower ?? 0)
            let pwrB = Double(viewModel.workoutManager.recorderB.powerSource?.cyclingPower ?? 0)
            let delta = pwrA - pwrB
            let percent = pwrB > 0 ? (delta / pwrB) * 100 : 0
            
            VStack(spacing: 4) {
                Text("\(Int(delta))W")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(abs(delta) > 10 ? .orange : .primary)
                
                Text(String(format: "%.1f%%", percent))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(width: 80)
        .padding(.top, 40)
    }
    
    private func sensorSetColumn(title: String, color: Color, recorder: SessionRecorder) -> some View {
        VStack(spacing: 0) {
            // Re-use sensorSetSection logic but optimized for column
            sensorSetSection(title: title, color: color, recorder: recorder, fields: viewModel.workoutManager.activeProfile.pages.first?.fields ?? [])
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
