import SwiftUI

@main
struct FitnessDeviceLabApp: App {
    @State private var settingsManager = SettingsManager.shared
    @State private var workoutManager: WorkoutSessionManager
    @State private var bluetoothManager: BluetoothManager

    init() {
        let settings = SettingsManager.shared
        self._settingsManager = State(initialValue: settings)
        self._workoutManager = State(initialValue: WorkoutSessionManager(settings: settings))
        self._bluetoothManager = State(initialValue: BluetoothManager.shared)
    }

    var body: some Scene {
        WindowGroup {
            BluetoothSelectorView()
                .environment(workoutManager)
                .environment(bluetoothManager)
                .environment(settingsManager)
        }
    }
}
