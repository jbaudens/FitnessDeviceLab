# Design Spec: App-Wide Localization (English & French)

## Overview
Implement a modern localization system using SwiftUI Environment and String Catalogs (`.xcstrings`). The system will support automatic system-language detection with a manual override in the app settings.

## Goals
- Support English (en) and French (fr).
- Provide a "System Default" option plus manual overrides.
- Use modern String Catalogs for translation management.
- Ensure the entire app UI updates instantly when the language is changed.

## Proposed Changes

### 1. Core Models (`Language.swift`)
- Introduce `AppLanguage` enum: `.system`, `.english`, `.french`.
- Implement a `locale` helper property to return the appropriate `Locale` object.

### 2. Settings Management (`SettingsManager.swift`)
- Add `language: AppLanguage` to `SettingsProvider` protocol and `SettingsManager` class.
- Persist selection to `UserDefaults` using the key `appLanguage`.
- Initialize from stored value, defaulting to `.system`.

### 3. App Root (`FitnessDeviceLabApp.swift`)
- Calculate `effectiveLocale` based on `settingsManager.language`.
- Inject the locale into the environment: `.environment(\.locale, effectiveLocale)`.

### 4. UI Updates (`SettingsView.swift`)
- Add a "Language" picker in the "App Settings" section.
- Support both iPhone (List row) and iPad/Mac (Segmented picker) layouts.

### 5. Translation Assets
- Create `Localizable.xcstrings`.
- Initial pass will include:
    - Settings labels ("Physical Profile", "FTP", "Weight", etc.)
    - Dashboard headers ("SET A", "PWR", "HR", "CAD")
    - Buttons ("Start", "Stop", "Reset")

## Success Criteria
- [ ] Users can switch language to French in Settings.
- [ ] The UI (Settings labels, Dashboard headers) instantly changes to French.
- [ ] Language preference persists after app restart.
- [ ] Choosing "System Default" follows the device's OS language settings.
