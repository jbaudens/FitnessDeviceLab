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
    let timer = SessionTimer()
    let errorManager = ErrorManager()
    let recorderA = SessionRecorder(settings: settings)
    let recorderB = SessionRecorder(settings: settings)
    let manager = WorkoutSessionManager(
        settings: settings, 
        locationProvider: locationManager, 
        sessionTimer: timer,
        recorderA: recorderA,
        recorderB: recorderB,
        errorManager: errorManager
    )
    let bluetooth = BluetoothManager(settings: settings, errorManager: errorManager)
    
    let devicesVM = DevicesViewModel(bluetoothManager: bluetooth)
    let workoutVM = WorkoutPlayerViewModel(workoutManager: manager, bluetoothManager: bluetooth, settings: settings)
    
    BluetoothSelectorView(
        devicesViewModel: devicesVM,
        workoutPlayerViewModel: workoutVM,
        workoutManager: manager,
        settingsManager: settings
    )
}
