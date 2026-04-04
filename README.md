# FitnessDeviceLab

A professional-grade iOS lab for cycling performance analysis and workout execution. This app is designed for power-meter-based training, featuring dual-power comparison, heart-rate-controlled workouts, and advanced cycling dynamics.

## 🚀 Features

- **Adaptive Lab UI:** A modular dashboard that prioritizes your most critical metrics during high-intensity sessions.
- **Dual-Power Lab:** Real-time comparison between two power sources (e.g., Smart Trainer vs. Pedal Power Meter) with thermal drift analysis and alignment tools.
- **Structured Workout Player:** Execute complex ERG and Heart-Rate-controlled workouts with anticipatory ramp blending.
- **Advanced Physics Engine:** Real-time calculation of Normalized Power (NP®), TSS®, IF®, and HRV metrics (DFA Alpha 1) for professional-grade physiological monitoring.
- **Multi-Sensor Bluetooth Hub:** Concurrent support for FTMS (Fitness Machine), Heart Rate, and Cycling Power sensors with high-frequency data parsing (up to 4Hz).
- **Cross-Platform Support:** Runs on iOS (iPhone/iPad) and macOS (Apple Silicon), providing a consistent lab experience across all your Apple devices.
- **Workout Editor:** A drag-and-drop visual interface for creating and modifying structured workouts.
- **Data Export:** Export your sessions in high-fidelity `.fit` and `.tcx` formats for analysis in platforms like TrainingPeaks or Strava.

## 📱 How to Use

### Setup & Connection
1. **Sensors:** Navigate to the **Devices** tab to scan for and connect your Bluetooth sensors.
   - Connect your primary trainer via **FTMS** for resistance control.
   - Connect secondary power sources for **Dual Power** analysis.
2. **Profile:** Set your **FTP** (Functional Threshold Power) and **LTHR** (Lactate Threshold Heart Rate) in the **Settings** tab to ensure all calculations and workout targets are personalized.

### Starting a Session
- **Free Ride:** Simply connect your sensors and hit the "Start" button on the dashboard for a free-ride session.
- **Structured Workouts:** Select a workout from the **Library**, review the steps, and tap "Start Workout". The app will automatically control your trainer to match the targets.

## 🛠 Development

### Tech Stack
- **Language:** Swift 6+ (Strict concurrency & `async/await`)
- **UI Framework:** SwiftUI with the `@Observable` framework
- **Architecture:** Clean MVVM (Model-View-ViewModel)
- **Dependency Injection:** Strictly constructor-based (no hidden singletons)

### Getting Started
1. Open `FitnessDeviceLab.xcodeproj` in **Xcode 16+**.
2. Select the **FitnessDeviceLab** scheme.
3. Target an **iOS 17+ Simulator** or Physical Device.
4. Build and Run (`⌘R`).

### Simulation for Testing
If you don't have hardware sensors nearby, the app includes a robust simulation mode:
- Enable **Simulated Devices** in the debug settings within the app.
- This provides simulated FTMS and Heart Rate data to test the UI and recording engine without needing a bike.

### Testing & Verification
We maintain high standards for logic and physics calculations:
- **Unit Tests:** Run `⌘U` to execute the `FitnessDeviceLabTests` suite. This covers all core engines, parsing logic, and setpoint calculations.
- **UI Tests:** The `FitnessDeviceLabUITests` suite verifies critical user flows and view transitions.

---
*Note: This project is a specialized lab tool intended for performance-focused athletes and engineers.*
