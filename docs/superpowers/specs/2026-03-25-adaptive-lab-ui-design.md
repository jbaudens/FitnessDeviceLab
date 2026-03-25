# Spec: Adaptive Lab Dashboard UI/UX

## Overview
Transforms FitnessDeviceLab into a high-performance "Lab" tool that scales from iPhone to iPad Pro 13" and macOS. Prioritizes landscape side-by-side analysis and fluid workflow-driven navigation.

## Navigation Architecture
- **Root Container**: `NavigationSplitView` (Sidebar/Detail pattern).
- **iPhone Behavior**: Collapses to standard Tab Bar.
- **iPad/macOS Behavior**: Persistent, collapsible Sidebar.
- **Auto-Collapse**: Sidebar hides or minimizes to icons during active workout to maximize chart space.

## Core User Flow (The 8 Steps)
1. **Devices**: Master-Detail layout. Left: sensor list. Right: Signal health & live raw data stream.
2. **Connection**: Smart connector appears once 1+ sensor is stable.
3. **Library**: Visual workout browser. Tapping a workout "loads" it into the Player Hub.
4. **Launchpad (Setup)**: Workout Tab shows Set A vs Set B mapping. Prominent "Start Free Ride" or "Start Workout" button.
5. **Pre-Flight**: Visual verification of target intensity vs connected hardware.
6. **Active Workout (Landscape)**: 
   - **Split Screen**: Left (Set A), Right (Set B).
   - **Center Column**: Live Delta (Watts/%) variance.
   - **Bottom Cockpit**: 72pt+ touch targets for Lap/Pause/Stop.
7. **Workout End**: Immediate transition to full-screen Comparison Lab.
8. **Export**: Multi-file summary with "Save All" and iCloud/Strava sharing.

## Technical Implementation
- **NavigationManager**: @Observable class to manage routing and mini-player state.
- **AdaptiveLayout Modifiers**: Custom view modifiers to handle orientation-specific padding and grid columns.
- **High-Density Components**: Refactored `DataFieldGrid` and `PerformanceChart` to support side-by-side scaling.
