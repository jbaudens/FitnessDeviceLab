# Swipeable Activity Profile Graphs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make workout graphs configurable per activity profile and swipeable in a unified dashboard container.

**Architecture:** Update `ActivityProfile` to hold an array of `GraphType` enums. Create a `SwipeableGraphContainer` using SwiftUI's `TabView` with `.page` style, using a factory pattern to render specialized or generic charts.

**Tech Stack:** Swift, SwiftUI, Swift Charts.

---

### Task 1: Update Activity Profile Data Model

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/Core/ActivityProfile.swift`
- Test: `FitnessDeviceLab/FitnessDeviceLabTests/LogicTests.swift`

- [ ] **Step 1: Add GraphType enum and graphs property**
- [ ] **Step 2: Update static profile instances with default graphs**
- [ ] **Step 3: Run build to verify types**
- [ ] **Step 4: Commit**

### Task 2: Create Swipeable Graph Components

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/WorkoutViews.swift`

- [ ] **Step 1: Implement GenericMetricGraphView**
- [ ] **Step 2: Implement GraphFactoryView**
- [ ] **Step 3: Implement SwipeableGraphContainer**
- [ ] **Step 4: Commit**

### Task 3: Integrate into Dashboard

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Components/AdaptiveWorkoutDashboard.swift`

- [ ] **Step 1: Update sensorSetStackedSection to use SwipeableGraphContainer**
- [ ] **Step 2: Update sensorSetSection to use SwipeableGraphContainer**
- [ ] **Step 3: Final Build and Run**
- [ ] **Step 4: Commit**
