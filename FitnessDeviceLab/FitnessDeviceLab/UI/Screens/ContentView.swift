import SwiftUI

struct ContentView: View {
    @Bindable var devicesViewModel: DevicesViewModel
    @Bindable var workoutPlayerViewModel: WorkoutPlayerViewModel
    
    let workoutManager: WorkoutSessionManager
    let settingsManager: SettingsManager

    var body: some View {
        TabView {
            // Tab 1: Devices
            NavigationStack {
                DevicesTabView(viewModel: devicesViewModel)
            }
            .tabItem {
                Label("Devices", systemImage: "antenna.radiowaves.left.and.right")
            }

            // Tab 2: Library
            NavigationStack {
                WorkoutLibraryView(
                    repository: WorkoutRepository.shared,
                    workoutManager: workoutManager,
                    settings: settingsManager
                )
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }

            // Tab 3: Workout
            NavigationStack {
                WorkoutPlayerView(viewModel: workoutPlayerViewModel)
            }
            .tabItem {
                Label("Workout", systemImage: "play.circle")
            }

            // Tab 4: Settings
            NavigationStack {
                SettingsView(settings: settingsManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    let settings = SettingsManager()
    let locationManager = LocationManager()
    let timer = SessionTimer()
    let recorderA = SessionRecorder(settings: settings)
    let recorderB = SessionRecorder(settings: settings)
    let manager = WorkoutSessionManager(
        settings: settings, 
        locationProvider: locationManager, 
        sessionTimer: timer,
        recorderA: recorderA,
        recorderB: recorderB
    )
    let bluetooth = BluetoothManager(settings: settings)
    
    let devicesVM = DevicesViewModel(bluetoothManager: bluetooth)
    let workoutVM = WorkoutPlayerViewModel(workoutManager: manager, bluetoothManager: bluetooth, settings: settings)
    
    ContentView(
        devicesViewModel: devicesVM,
        workoutPlayerViewModel: workoutVM,
        workoutManager: manager,
        settingsManager: settings
    )
}
