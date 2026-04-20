# App-Wide Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement app-wide localization (English and French) with a manual override in settings.

**Architecture:** Use Approach 1 (Integrated SettingsManager). Inject `Locale` into the SwiftUI environment at the app root. Use String Catalogs (`.xcstrings`) for translations.

**Tech Stack:** Swift, SwiftUI, String Catalogs.

---

### Task 1: Core Localization Model

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/Core/Language.swift`

- [ ] **Step 1: Define AppLanguage enum with cases .system, .english, .french**
- [ ] **Step 2: Commit**

### Task 2: Settings and App Integration

**Files:**
- Modify: `FitnessDeviceLab/FitnessDeviceLab/Services/Settings/SettingsManager.swift`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/FitnessDeviceLabApp.swift`

- [ ] **Step 1: Update SettingsProvider and SettingsManager to store/persist AppLanguage**
- [ ] **Step 2: Update FitnessDeviceLabApp to inject effective locale into environment**
- [ ] **Step 3: Commit**

### Task 3: Localization Assets & Settings UI

**Files:**
- Create: `FitnessDeviceLab/FitnessDeviceLab/Localizable.xcstrings`
- Modify: `FitnessDeviceLab/FitnessDeviceLab/UI/Screens/SettingsView.swift`

- [ ] **Step 1: Create Localizable.xcstrings with initial English/French keys**
- [ ] **Step 2: Add Language selection picker to SettingsView (both layouts)**
- [ ] **Step 3: Verify build and basic language switching**
- [ ] **Step 4: Commit**

### Task 4: App-Wide Translation Rollout

**Files:**
- Modify: Multiple UI components and strings.

- [ ] **Step 1: Systematically replace hardcoded strings with LocalizedStringKey where necessary**
- [ ] **Step 2: Populate all keys in Localizable.xcstrings**
- [ ] **Step 3: Final Build and verification**
- [ ] **Step 4: Commit**
