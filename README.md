# FitnessDeviceLab

FitnessDeviceLab is a specialized iOS application designed for fitness enthusiasts and researchers to record and compare data from multiple Bluetooth fitness devices simultaneously. It supports heart rate monitors, cycling power meters, and smart trainers.

## Architecture Overview

The application is built using **SwiftUI** for the user interface and **Combine** for reactive data management. The architecture follows a modular approach with clear separation of concerns between hardware communication, data processing, and session management.

### Core Components

#### 1. Bluetooth Management (`BluetoothManager.swift`)
The `BluetoothManager` is a singleton responsible for the lifecycle of Bluetooth connections.
- **Discovery**: Scans for standard fitness service UUIDs (Heart Rate, Cycling Power, Fitness Machine).
- **Connection Management**: Handles connecting, disconnecting, and automatic reconnection of peripherals.
- **Device Abstraction**: Wraps `CBPeripheral` into `DiscoveredPeripheral` objects which handle the low-level parsing of Bluetooth characteristics.

#### 2. Peripheral Data Parsing (`DiscoveredPeripheral`)
Located within the Bluetooth management layer, this class implements `CBPeripheralDelegate`.
- **Parsing**: Converts raw byte arrays from Bluetooth characteristics into meaningful metrics:
  - **Heart Rate**: BPM and high-precision RR intervals.
  - **Cycling Power Meter**: Instantaneous power (Watts), cadence (RPM), and L/R power balance.
  - **Fitness Machine (Smart Trainers)**: Power and cadence from indoor bike data.
- **Reactive Updates**: Uses `@Published` properties to broadcast live updates to the UI and recording engines.

#### 3. Session Orchestration (`WorkoutSessionManager.swift`)
The central "brain" of the application that manages the state of a workout.
- **Dual Recording**: Uniquely supports two independent recording profiles (Profile A and Profile B), allowing users to compare two sets of devices in real-time.
- **Workout Execution**: Manages structured workout steps, timers, and the overall progression of a session.
- **Data Coordination**: Orchestrates the flow of data from Bluetooth devices to the recording engines and persistence layers.

#### 4. Data Persistence (`SessionRecorder.swift`)
Responsible for capturing the timeline of a workout.
- **Trackpoints**: Every second, it captures a `Trackpoint` containing HR, power, cadence, altitude, and RR intervals.
- **TCX Export**: Implements a native exporter for the **Training Center XML (TCX)** format, ensuring compatibility with platforms like Strava, Garmin Connect, and TrainingPeaks.

#### 5. Real-time Analysis (`DataFieldEngine.swift` & `HRVEngine.swift`)
- **DataFieldEngine**: A sophisticated processing engine that computes real-time statistics beyond simple averages.
  - **Altitude Compensation**: Automatically calculates equivalent power at Sea Level and "Home" altitude using standardized physiological models, allowing for consistent effort comparison across different environments.
  - **Advanced Power Metrics**: Implements rolling averages (3s, 10s, 30s) and complex metrics like **Normalized Power (NP)**, **Intensity Factor (IF)**, and **Training Stress Score (TSS)**.
  - **Reactive UI**: Publishes updates that are directly consumed by the workout dashboard.
- **HRVEngine**: Specialized logic for processing high-frequency RR intervals to provide Heart Rate Variability insights, offloaded to background threads to ensure UI responsiveness.

### Data Flow

1.  **Ingestion**: `DiscoveredPeripheral` receives raw data via Bluetooth notifications.
2.  **Transformation**: Raw bytes are parsed into typed properties.
3.  **Collection**: Every second, the `WorkoutSessionManager` triggers a "tick", prompting the `SessionRecorder` to snapshot the current state of all connected sensors.
4.  **Display**: SwiftUI views (`WorkoutPlayerView`, `DataFieldViews`) observe the `WorkoutSessionManager` and `DataFieldEngine` to update the UI.
5.  **Persistence**: Upon stopping the workout, the `SessionRecorder` serializes the collection of trackpoints into a TCX file stored in the app's temporary directory.

## Technical Highlights

- **Precise Timing**: Uses Combine-based timers for consistent 1Hz recording intervals.
- **Standard Compliance**: Implements official Bluetooth SIG GATT profiles for Fitness Machines and Cycling Power.
- **Extensibility**: The modular design allows for easy addition of new sensor types (e.g., Running Dynamics, Core Temperature) by extending the `DiscoveredPeripheral` parsing logic.
- **Research Oriented**: The ability to record two profiles simultaneously makes it an ideal tool for validating new sensors against "gold standard" devices.
