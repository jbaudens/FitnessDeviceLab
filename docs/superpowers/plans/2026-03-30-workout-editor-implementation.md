# Workout Editor (Pro Lab) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a visual workout editor and unify the workout library into a single, editable persistent collection.

**Architecture:** Use a dedicated `WorkoutEditorView` with a `@Observable` view model to manage the draft state. Persistence will be handled by an updated `WorkoutRepository` using `UserDefaults` (JSON) for simple, reliable storage.

**Tech Stack:** SwiftUI, Swift 6, JSON Persistence.

---

### Task 1: Persistent Workout Library

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/Features/Library/WorkoutRepository.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/Core/WorkoutModels.swift`

- [ ] **Step 1: Ensure `StructuredWorkout` and `WorkoutStep` are fully `Codable`**
- [ ] **Step 2: Refactor `WorkoutRepository` to use a local JSON file or UserDefaults for storage**
- [ ] **Step 3: Implement "First-Run Seeding" logic**
```swift
private func seedDefaults() {
    if !hasBeenSeeded {
        self.save(DefaultWorkouts.all)
        hasBeenSeeded = true
    }
}
```
- [ ] **Step 4: Add CRUD methods to `WorkoutRepository`**
- [ ] **Step 5: Verify seeding by running the app and checking the library**
- [ ] **Step 6: Commit**

### Task 2: Editor Shell & Navigation

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutEditorView.swift`
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutEditorViewModel.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/WorkoutLibraryView.swift`

- [ ] **Step 1: Create `WorkoutEditorViewModel` to hold the `@Observable` draft workout**
- [ ] **Step 2: Implement `WorkoutEditorView` with the `WorkoutSummaryHeader`**
- [ ] **Step 3: Update `WorkoutLibraryView` with a (+) button and "Edit" context menus**
- [ ] **Step 4: Verify navigation to the editor works for both new and existing workouts**
- [ ] **Step 5: Commit**

### Task 3: Visual Timeline & Drag-and-Drop

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/WorkoutTimelineCanvas.swift`
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/StepPalette.swift`

- [ ] **Step 1: Build `WorkoutTimelineCanvas` using `ScrollView` and `HStack`**
- [ ] **Step 2: Create `WorkoutStepBlock` styled like the player's graph**
- [ ] **Step 3: Implement `StepPalette` with draggable templates**
- [ ] **Step 4: Implement `.onInsert` or custom drop logic on the timeline**
- [ ] **Step 5: Verify blocks can be added and reordered**
- [ ] **Step 6: Commit**

### Task 4: Precision Step Inspector

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/StepInspector.swift`

- [ ] **Step 1: Build the `StepInspector` UI for single-step selection**
- [ ] **Step 2: Add numeric inputs for Duration and Intensity %**
- [ ] **Step 3: Implement the "Ramp" toggle logic**
- [ ] **Step 4: Verify that editing values in the inspector updates the timeline visually**
- [ ] **Step 5: Commit**

### Task 5: Lasso Selection & Multi-Edit

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/WorkoutTimelineCanvas.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/StepInspector.swift`

- [ ] **Step 1: Add a `LassoGesture` to the timeline background**
- [ ] **Step 2: Implement intersection logic to select blocks within the lasso rect**
- [ ] **Step 3: Update `StepInspector` to show "Group Actions" (Duplicate/Delete) when multiple items are selected**
- [ ] **Step 4: Verify that "Duplicate Set" works correctly for complex groups**
- [ ] **Step 5: Commit**

### Task 6: Final Integration & Validation

- [ ] **Step 1: Implement the "Save" flow with final validation (name, duration > 0)**
- [ ] **Step 2: Add a "Clone" action to the `WorkoutLibraryView`**
- [ ] **Step 3: Verify the full end-to-end loop: Create -> Edit -> Save -> Play**
- [ ] **Step 4: Run all XCTests to ensure 100% pass rate**
- [ ] **Step 5: Commit**
