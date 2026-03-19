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

#Preview {
    let settings = SettingsManager()
    let locationManager = LocationManager()
    let timer = WorkoutTimer()
    let manager = WorkoutSessionManager(settings: settings, locationProvider: locationManager, workoutTimer: timer)
    let bluetooth = BluetoothManager(settings: settings)
    
    let devicesVM = DevicesViewModel(bluetoothManager: bluetooth)
    let workoutVM = WorkoutPlayerViewModel(workoutManager: manager, bluetoothManager: bluetooth, settings: settings)
    
    BluetoothSelectorView(
        devicesViewModel: devicesVM,
        workoutPlayerViewModel: workoutVM,
        workoutManager: manager,
        settingsManager: settings
    )
}
