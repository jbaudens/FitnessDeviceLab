import SwiftUI

@main
struct FitnessDeviceLabApp: App {
    @State private var settingsManager: SettingsManager
    @State private var workoutManager: WorkoutSessionManager
    @State private var bluetoothManager: BluetoothManager
    private let locationManager = LocationManager()

    init() {
        let settings = SettingsManager()
        self._settingsManager = State(initialValue: settings)
        self._workoutManager = State(initialValue: WorkoutSessionManager(settings: settings, locationProvider: locationManager))
        self._bluetoothManager = State(initialValue: BluetoothManager(settings: settings))
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
