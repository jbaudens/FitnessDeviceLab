# Adaptive Lab Dashboard UI/UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a responsive navigation system and an adaptive workout dashboard that scales from iPhone to iPad/macOS, specifically optimized for side-by-side sensor analysis on larger screens.

**Architecture:** Use `NavigationSplitView` as the root container for iPad/macOS and `TabView` for iPhone, managed by a centralized `NavigationManager`. The `WorkoutPlayerView` will adapt its layout based on horizontal size class and orientation.

**Tech Stack:** SwiftUI, Swift 6 Observation framework (`@Observable`), `NavigationSplitView`.

---

### Task 1: Navigation Infrastructure & Root Container

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/NavigationManager.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/FitnessDeviceLabApp.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/ContentView.swift`

- [ ] **Step 1: Create NavigationManager**
  Define `AppTab` enum and `@Observable class NavigationManager`.
  
```swift
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case devices = "Devices"
    case library = "Library"
    case workout = "Workout"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .devices: return "antenna.radiowaves.left.and.right"
        case .library: return "books.vertical"
        case .workout: return "play.circle"
        case .settings: return "gear"
        }
    }
}

@Observable
class NavigationManager {
    var selectedTab: AppTab? = .devices
    var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    var isSidebarCollapsed: Bool = false
    
    // Track workout state to auto-collapse sidebar
    var isWorkoutActive: Bool = false {
        didSet {
            if isWorkoutActive {
                sidebarVisibility = .all
            }
        }
    }
}
```

- [ ] **Step 2: Inject NavigationManager into FitnessDeviceLabApp**
  Add `@State private var navigationManager = NavigationManager()` and pass it to `ContentView`.

- [ ] **Step 3: Refactor ContentView to use NavigationSplitView & TabView**
  Use `horizontalSizeClass` to switch between `NavigationSplitView` and `TabView`.

```swift
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var navigationManager: NavigationManager
    // ... existing view models ...

    var body: some View {
        if horizontalSizeClass == .compact {
            tabRoot
        } else {
            splitRoot
        }
    }

    private var tabRoot: some View {
        TabView(selection: $navigationManager.selectedTab) {
            // ... tabs ...
        }
    }

    private var splitRoot: some View {
        NavigationSplitView(columnVisibility: $navigationManager.sidebarVisibility) {
            List(AppTab.allCases, selection: $navigationManager.selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
            }
            .navigationTitle("Lab Dashboard")
        } detail: {
            if let tab = navigationManager.selectedTab {
                detailView(for: tab)
            } else {
                Text("Select a tab")
            }
        }
    }
    
    @ViewBuilder
    private func detailView(for tab: AppTab) -> some View {
        switch tab {
        case .devices: DevicesTabView(viewModel: devicesViewModel)
        case .library: WorkoutLibraryView(...)
        case .workout: WorkoutPlayerView(viewModel: workoutPlayerViewModel)
        case .settings: SettingsView(settings: settingsManager)
        }
    }
}
```

- [ ] **Step 4: Commit**
  `git commit -m "feat: implement adaptive navigation root with NavigationManager"`

### Task 2: Side-by-Side Workout Dashboard (Landscape Lab Mode)

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutPlayerView.swift`
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/AdaptiveWorkoutDashboard.swift`

- [ ] **Step 1: Extract Dashboard to AdaptiveWorkoutDashboard**
  Move the active workout view logic to a new component that can handle different layouts.

- [ ] **Step 2: Implement Side-by-Side Layout for Landscape iPad**
  Use `GeometryReader` and `horizontalSizeClass` to detect landscape iPad. Show Set A on left, Set B on right.

```swift
struct AdaptiveWorkoutDashboard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    // ...
    var body: some View {
        GeometryReader { geo in
            if geo.size.width > 800 && horizontalSizeClass != .compact {
                // Landscape Lab Mode
                HStack(spacing: 0) {
                    sensorSetColumn(recorderA, color: .blue)
                    varianceColumn
                    sensorSetColumn(recorderB, color: .purple)
                }
            } else {
                // Portrait/Mobile Mode (Existing layout)
                VStack { ... }
            }
        }
    }
}
```

- [ ] **Step 3: Implement Live Delta (Variance) Column**
  Show the difference between Power A and Power B in a central column.

- [ ] **Step 4: Commit**
  `git commit -m "feat: implement side-by-side adaptive workout dashboard for iPad"`

### Task 3: Interactive Cockpit Refactoring (Large Touch Targets)

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutPlayerView.swift`

- [ ] **Step 1: Update InteractionCockpit for iPad**
  Increase button sizes to 72pt+ for primary controls on iPad.
- [ ] **Step 2: Commit**
  `git commit -m "style: optimize interaction cockpit for iPad touch targets"`

### Task 4: Auto-Collapse & Final Polishing

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutPlayerViewModel.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutPlayerView.swift`

- [ ] **Step 1: Link NavigationManager to Workout State**
  Ensure `navigationManager.isWorkoutActive` is updated when a workout starts/stops.
- [ ] **Step 2: Hide Sidebar during Workout on iPad**
  Use `navigationSplitViewColumnVisibility(.detailOnly)` or similar during active workout.
- [ ] **Step 3: Commit**
  `git commit -m "feat: auto-collapse sidebar during active workout on iPad"`

---
