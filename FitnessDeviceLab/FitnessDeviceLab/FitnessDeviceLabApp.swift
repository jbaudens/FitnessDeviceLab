import SwiftUI

@main
struct FitnessDeviceLabApp: App {
    @State private var settingsManager: SettingsManager
    @State private var workoutManager: WorkoutSessionManager
    @State private var bluetoothManager: BluetoothManager
    @State private var errorManager: ErrorManager
    
    @State private var devicesViewModel: DevicesViewModel
    @State private var workoutPlayerViewModel: WorkoutPlayerViewModel
    
    private let locationManager = LocationManager()
    private let sessionTimer = SessionTimer()

    init() {
        let error = ErrorManager()
        let settings = SettingsManager()
        let recorderA = SessionRecorder(settings: settings)
        let recorderB = SessionRecorder(settings: settings)
        let workout = WorkoutSessionManager(
            settings: settings, 
            locationProvider: locationManager, 
            sessionTimer: sessionTimer,
            recorderA: recorderA,
            recorderB: recorderB,
            errorManager: error
        )
        let bluetooth = BluetoothManager(settings: settings, errorManager: error)
        
        self._errorManager = State(initialValue: error)
        self._settingsManager = State(initialValue: settings)
        self._workoutManager = State(initialValue: workout)
        self._bluetoothManager = State(initialValue: bluetooth)
        
        self._devicesViewModel = State(initialValue: DevicesViewModel(bluetoothManager: bluetooth))
        self._workoutPlayerViewModel = State(initialValue: WorkoutPlayerViewModel(workoutManager: workout, bluetoothManager: bluetooth, settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                devicesViewModel: devicesViewModel,
                workoutPlayerViewModel: workoutPlayerViewModel,
                workoutManager: workoutManager,
                settingsManager: settingsManager
            )
            .environment(errorManager)
        }
    }
}
