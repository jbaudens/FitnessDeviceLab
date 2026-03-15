import SwiftUI

@main
struct FitnessDeviceLabApp: App {
    @State private var workoutManager = WorkoutSessionManager()
    @State private var settingsManager = SettingsManager.shared

    var body: some Scene {
        WindowGroup {
            BluetoothSelectorView()
                .environment(workoutManager)
                .environment(settingsManager)
        }
    }
}
