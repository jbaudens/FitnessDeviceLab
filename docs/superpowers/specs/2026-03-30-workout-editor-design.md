# Workout Editor (Pro Lab) Design Spec

Enabling users (specifically performance athletes) to visually create, edit, and manage structured workouts directly within FitnessDeviceLab.

## Goal
To provide a high-precision, visual workstation for building workouts that are compatible with the existing `WorkoutPlayer`, integrated into a unified and fully editable workout library.

## Architecture & Components

### 1. `WorkoutEditorView` (Main Container)
The top-level view managing the editor state, including the `StructuredWorkout` being drafted, the current selection, and undo/redo history.

### 2. `WorkoutSummaryHeader`
A persistent header aligned with the `WorkoutPlayer` visual style.
- **Metrics:** Live calculation of **Total Duration**, **TSS**, and **IF** using `WorkoutPhysicsEngine`.
- **Title:** Inline editable text field for the workout name.
- **Actions:** A prominent "SAVE" button that triggers the validation and persistence flow.

### 3. `WorkoutTimelineCanvas` (The Workspace)
A horizontal, scrollable interactive chart where the workout "profile" is built.
- **Visual Style:** Matching `WorkoutGraphView` (monospaced fonts, zone-based colors, dashed grid lines).
- **Interactive Blocks:**
    - Width proportional to duration.
    - Height proportional to intensity (% FTP/LTHR).
    - Support for `RampShape` (trapezoidal) blocks.
- **Interaction Models:**
    - **Lasso Selection:** Dragging on the canvas background creates a selection rectangle to select multiple blocks.
    - **Drag & Drop:** Supports receiving dropped templates from the `StepPalette`.
    - **Reordering:** Dragging a block horizontally to move it within the sequence.

### 4. `StepPalette`
A side/bottom tray containing draggable templates:
- **Warmup:** Default duration 10m, low intensity (Z1).
- **Work:** Default duration 5m, high intensity (Z4).
- **Recovery:** Default duration 2m, low intensity (Z2).
- **Cooldown:** Default duration 10m, low intensity (Z1).

### 5. `StepInspector` (Precision Editor)
A dedicated panel for fine-tuning the selected step(s).
- **Single Selection:**
    - **Duration:** Precise time picker or numeric input.
    - **Target %:** Slider and numeric input for start intensity.
    - **Ramp Toggle:** When enabled, reveals an "End Target %" field.
- **Multi-Selection (Group Actions):**
    - **Duplicate Set:** Appends a copy of the selected group to the end of the selection.
    - **Delete Group:** Removes all selected blocks.

## Data Flow & Persistence (Unified Library)

### 1. Persistent Storage
- Transition `WorkoutRepository` to manage a mutable collection of workouts.
- **First-Run Seeding:** On the first launch of the app with this feature, the `DefaultWorkouts.all` list is copied into the persistent store (e.g., via `SwiftData` or a JSON-backed local file).
- From this point forward, the "Stock" workouts are treated as user-owned and can be modified or deleted.

### 2. State Management
- **DraftWorkout:** A `@Observable` state representing the workout currently being edited.
- **SelectionManager:** Tracks the UUIDs of selected steps for highlighting and group actions.

### 3. Library Integration
- **WorkoutLibraryView:** Add a prominent **(+)** button to create a new workout.
- **Unified Actions:** Every workout row provides "Edit" (opens the editor), "Clone" (duplicates and opens editor), and "Delete" (removes from persistence).

## Testing Strategy
- **Unit Tests:**
    - Test TSS/IF calculations for complex interval sets (including ramps).
    - Test first-run seeding logic (ensure defaults are copied correctly).
    - Test persistence (save/load/delete) of `StructuredWorkout` objects.
    - Test the `Duplicate Set` logic to ensure IDs are regenerated and order is maintained.
- **UI Tests:**
    - Verify drag-and-drop from palette to timeline.
    - Verify lasso selection highlights the correct blocks.
    - Verify inspector updates correctly when switching between single and multi-selection.

## Visual Consistency
- **Colors:** Strictly using `WorkoutZone.color` for all blocks.
- **Typography:** Using rounded monospaced fonts for all numeric data, matching the `WorkoutPlayer`.
- **Layout:** "Split View" approach to keep the chart visible while editing details.
