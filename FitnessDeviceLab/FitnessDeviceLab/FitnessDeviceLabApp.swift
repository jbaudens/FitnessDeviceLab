import SwiftUI

@main
struct FitnessDeviceLabApp: App {
    @State private var settingsManager: SettingsManager
    @State private var workoutManager: WorkoutSessionManager
    @State private var bluetoothManager: BluetoothManager
    
    @State private var devicesViewModel: DevicesViewModel
    @State private var workoutPlayerViewModel: WorkoutPlayerViewModel
    
    private let locationManager = LocationManager()
    private let workoutTimer = WorkoutTimer()

    init() {
        let settings = SettingsManager()
        let workout = WorkoutSessionManager(settings: settings, locationProvider: locationManager, workoutTimer: workoutTimer)
        let bluetooth = BluetoothManager(settings: settings)
        
        self._settingsManager = State(initialValue: settings)
        self._workoutManager = State(initialValue: workout)
        self._bluetoothManager = State(initialValue: bluetooth)
        
        self._devicesViewModel = State(initialValue: DevicesViewModel(bluetoothManager: bluetooth))
        self._workoutPlayerViewModel = State(initialValue: WorkoutPlayerViewModel(workoutManager: workout, bluetoothManager: bluetooth, settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            BluetoothSelectorView(
                devicesViewModel: devicesViewModel,
                workoutPlayerViewModel: workoutPlayerViewModel
            )
            .environment(workoutManager)
            .environment(bluetoothManager)
            .environment(settingsManager)
        }
    }
}
