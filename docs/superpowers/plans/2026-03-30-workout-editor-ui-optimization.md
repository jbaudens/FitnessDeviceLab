# Workout Editor UI Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize the Workout Editor for iPad and macOS with a "Horizon" command bar and collapsible workout info, while maintaining functionality on iPhone.

**Architecture:** Create a `CollapsibleWorkoutInfo` component. Refactor `WorkoutEditorView` to use a horizontal stack for the palette and inspector on wide screens.

**Tech Stack:** SwiftUI, Swift 6.

---

### Task 1: Collapsible Workout Info

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/CollapsibleWorkoutInfo.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutEditorView.swift`

- [ ] **Step 1: Create `CollapsibleWorkoutInfo` component**
```swift
struct CollapsibleWorkoutInfo: View {
    @Binding var name: String
    @Binding var description: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Workout Name", text: $name)
                    .font(.headline)
                Spacer()
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            if isExpanded {
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
}
```
- [ ] **Step 2: Replace the `Form` in `WorkoutEditorView` with the new component**
- [ ] **Step 3: Commit**

### Task 2: "Horizon" Command Bar Foundation

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutEditorView.swift`

- [ ] **Step 1: Define adaptive layout for Palette and Inspector**
- [ ] **Step 2: Use `HStack` on wide screens (`horizontalSizeClass == .regular`) and `VStack` on narrow screens**
- [ ] **Step 3: Commit**

### Task 3: Refactored Palette (Grid Style)

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/StepPalette.swift`

- [ ] **Step 1: Update `StepPalette` to support a 2x2 grid layout**
- [ ] **Step 2: Ensure buttons are compact and labeled correctly**
- [ ] **Step 3: Commit**

### Task 4: Refactored Inspector (Compact Horizon Style)

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/StepInspector.swift`

- [ ] **Step 1: Update `StepInspector` to be more compact for horizontal placement**
- [ ] **Step 2: Place reorder arrows, duplicate, and delete icons in a single row**
- [ ] **Step 3: Ensure the intensity slider and duration fields fit neatly**
- [ ] **Step 4: Commit**

### Task 5: Final Polish & iPhone Compatibility

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutEditorView.swift`

- [ ] **Step 1: Ensure deletion confirmation still works correctly**
- [ ] **Step 2: Verify layout on iPhone (vertical stack) and iPad (horizontal bar)**
- [ ] **Step 3: Verify the "Delete Workout" button is still accessible (move to the bottom of the info section)**
- [ ] **Step 4: Commit**
