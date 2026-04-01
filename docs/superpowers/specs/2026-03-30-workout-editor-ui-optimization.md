# Workout Editor UI Optimization Spec

Optimizing the Workout Editor for iPad and macOS to provide a desktop-class experience while keeping the iPhone version functional and compact.

## Goal
To move interaction controls closer to the visual timeline and maximize vertical space by making workout metadata collapsible.

## Architecture & Layout Changes

### 1. Collapsible Workout Info (Top)
- **Component:** `CollapsibleWorkoutInfo`
- **Behavior:** 
    - Defaults to a single row showing the **Workout Name** and an "Expand" chevron.
    - When expanded, reveals the **Description** text field.
- **Placement:** Top of the `WorkoutEditorView`.

### 2. Large Visual Timeline (Middle)
- **Constraint:** Occupies 60-70% of the remaining vertical space.
- **Scaling:** Maintained at 250% (2.5) as implemented.

### 3. The "Horizon" Command Bar (Bottom)
- **Constraint:** Placed directly below the timeline.
- **Layout (iPad/macOS):** A horizontal container split into two main sections:
    - **Palette Section (Left):** Grid of buttons for Warmup, Work, Recovery, and Cooldown. Tapping a button adds the step immediately.
    - **Inspector Section (Right):** 
        - Top row: Contextual label, reorder arrows (←, →), Duplicate icon, and Delete icon.
        - Bottom row: Horizontal intensity slider and a compact duration input.
- **Layout (iPhone):** 
    - The "Horizon" bar will stack vertically if the screen width is too narrow.
    - Reorder buttons and action icons remain close to the timeline.

## Interaction Enhancements
- **Immediate Feedback:** Reorder arrows provide a reliable alternative to drag-and-drop.
- **Visual Grouping:** Selected intervals are highlighted with a prominent blue border.
- **Safe Transitions:** Continued use of the "Local Draft" pattern in the inspector to prevent crashes during deletions.

## Implementation Steps (Summary)
1. Refactor `WorkoutEditorView` to use the new collapsible info section.
2. Redesign `StepPalette` and `StepInspector` to fit into the "Horizon" bar.
3. Add adaptive layout logic to switch between horizontal and vertical stacks based on horizontal size class.

## Testing Strategy
- **UI Tests:**
    - Verify collapsible info section expands/collapses.
    - Verify reorder buttons correctly update the step sequence.
    - Verify adaptive layout on different device orientations (Simulator).
