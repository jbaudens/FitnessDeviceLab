# FitnessDeviceLab: Architectural Overview

The FitnessDeviceLab architecture is built on a "Service-Engine-UI" pattern with a heavy emphasis on **Protocol-Oriented Programming (POP)** to abstract away hardware complexities.

## 1. Hardware Abstraction Layer (HAL)
The foundation is the `SensorPeripheral` protocol.
*   **Generic Peripheral**: Represents any BLE device.
*   **Role Adapters**: `HeartRateSensor`, `PowerSensor`, etc., wrap the generic peripheral to expose only relevant data.
*   **Simulated Peripherals**: The system allows for `SimulatedPeripheral` implementations, enabling UI development and testing without physical hardware.

## 2. The Engine Layer
The "Brains" of the application are split into specialized engines:
*   **DataFieldEngine**: Calculates "Standard," "Sea Level," and "Home" metrics. It handles the complex math for Normalized Power (NP) and Training Stress Score (TSS).
*   **HRVEngine**: Processes raw RR intervals to provide real-time recovery and stress metrics (SDNN, RMSSD).
*   **TrainerSetpointCalculator**: The control logic for smart trainers. It supports anticipatory logic (ramping power 2 seconds before a step starts) to compensate for trainer lag.
*   **WorkoutPhysicsEngine**: (In progress) Aims to simulate speed and distance based on power, weight, and virtual terrain.

## 3. Data Flow & Orchestration
The **`WorkoutSessionManager`** is the central hub.
1.  **Input**: Receives data from `BluetoothManager` at ~1-2Hz.
2.  **Processing**: Routes data to two parallel `SessionRecorders` and two `DataFieldEngines`.
3.  **Control**: Uses the `TrainerSetpointCalculator` to decide what wattage/resistance to send back to the hardware via `TrainerController`.
4.  **Observation**: Exposes its state via the `@Observable` framework, which the SwiftUI views listen to.

## 4. The Dual-Recorder System
Unique to this app is the ability to maintain two independent data streams (`Stream A` and `Stream B`).
*   **Purpose**: Allows athletes to compare a "Reference" power meter (e.g., pedals) against a "Control" device (e.g., smart trainer).
*   **Export**: Generates two sets of `.fit` or `.tcx` files for side-by-side analysis in tools like GoldenCheetah or ZwiftPower.

## 5. UI Structure
The UI follows a strict MVVM pattern.
*   **Screens**: Large-scale containers (`WorkoutPlayerView`, `LibraryView`).
*   **ViewModels**: Manage view-specific state and interact with the `WorkoutSessionManager`.
*   **Components**: Atomic UI units (`DataFieldViews`, `BluetoothSelectorView`) designed for reuse across different device profiles.
