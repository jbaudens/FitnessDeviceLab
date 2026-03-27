# Side-by-Side Workout Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a responsive dashboard that displays Set A and Set B side-by-side on larger screens (Landscape Lab Mode).

**Architecture:** Extract the active workout view logic from `WorkoutPlayerView.swift` into a new `AdaptiveWorkoutDashboard` component. This component will use `GeometryReader` and `horizontalSizeClass` to switch between a side-by-side layout for large screens and the existing stacked layout for mobile/portrait.

**Tech Stack:** SwiftUI, Swift

---

### Task 1: Create AdaptiveWorkoutDashboard.swift

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/AdaptiveWorkoutDashboard.swift`

- [ ] **Step 1: Write the failing test** (Since this is a UI component, we'll verify it visually and through integration in Task 2, but we'll add a preview to verify the layout).

- [ ] **Step 2: Implement `AdaptiveWorkoutDashboard`**

```swift
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
```

- [ ] **Step 3: Commit**

```bash
git add FitnessDeviceLab/FitnessDeviceLab/UI/Components/AdaptiveWorkoutDashboard.swift
git commit -m "feat: create AdaptiveWorkoutDashboard component"
```

### Task 2: Update WorkoutPlayerView.swift

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutPlayerView.swift`

- [ ] **Step 1: Replace `activeView` TabView with `AdaptiveWorkoutDashboard`**

- [ ] **Step 2: Clean up redundant private methods in `WorkoutPlayerContentView`** (like `sensorSetSection`).

- [ ] **Step 3: Verify the app builds**

Run: `xcodebuild -project FitnessDeviceLab/FitnessDeviceLab.xcodeproj -scheme FitnessDeviceLab -destination 'platform=iOS Simulator,name=iPhone 15' build`

- [ ] **Step 4: Commit**

```bash
git add FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutPlayerView.swift
git commit -m "refactor: use AdaptiveWorkoutDashboard in WorkoutPlayerView"
```
