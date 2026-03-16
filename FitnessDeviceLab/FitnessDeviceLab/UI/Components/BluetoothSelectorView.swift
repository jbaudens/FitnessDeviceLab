import SwiftUI

struct BluetoothSelectorView: View {
    @Bindable var devicesViewModel: DevicesViewModel
    @Bindable var workoutPlayerViewModel: WorkoutPlayerViewModel
    let workoutManager: WorkoutSessionManager
    let settingsManager: SettingsManager
    
    var body: some View {
        ContentView(
            devicesViewModel: devicesViewModel,
            workoutPlayerViewModel: workoutPlayerViewModel,
            workoutManager: workoutManager,
            settingsManager: settingsManager
        )
    }
}
