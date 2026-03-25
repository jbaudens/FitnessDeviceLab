import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var navigationManager: NavigationManager
    @Bindable var devicesViewModel: DevicesViewModel
    @Bindable var workoutPlayerViewModel: WorkoutPlayerViewModel
    
    let workoutManager: WorkoutSessionManager
    let settingsManager: SettingsManager
    
    @Environment(ErrorManager.self) private var errorManager

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                tabRoot
            } else {
                splitRoot
            }
        }
        .alert(
            item: Binding(
                get: { errorManager.currentError.map { IdentifiableError(error: $0) } },
                set: { _ in errorManager.dismiss() }
            )
        ) { wrapper in
            Alert(
                title: Text("Error"),
                message: Text(wrapper.error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var tabRoot: some View {
        TabView(selection: $navigationManager.selectedTab) {
            // Tab 1: Devices
            NavigationStack {
                DevicesTabView(viewModel: devicesViewModel)
            }
            .tabItem {
                Label("Devices", systemImage: "antenna.radiowaves.left.and.right")
            }
            .tag(AppTab.devices)

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
            .tag(AppTab.library)

            // Tab 3: Workout
            NavigationStack {
                WorkoutPlayerView(viewModel: workoutPlayerViewModel)
            }
            .tabItem {
                Label("Workout", systemImage: "play.circle")
            }
            .tag(AppTab.workout)

            // Tab 4: Settings
            NavigationStack {
                SettingsView(settings: settingsManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(AppTab.settings)
        }
    }

    private var splitRoot: some View {
        NavigationSplitView(columnVisibility: $navigationManager.sidebarVisibility) {
            List(AppTab.allCases, selection: $navigationManager.selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
            }
            .navigationTitle("Lab Dashboard")
        } detail: {
            if let tab = navigationManager.selectedTab {
                detailView(for: tab)
            } else {
                Text("Select a tab")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func detailView(for tab: AppTab) -> some View {
        switch tab {
        case .devices:
            NavigationStack {
                DevicesTabView(viewModel: devicesViewModel)
            }
        case .library:
            NavigationStack {
                WorkoutLibraryView(
                    repository: WorkoutRepository.shared,
                    workoutManager: workoutManager,
                    settings: settingsManager
                )
            }
        case .workout:
            NavigationStack {
                WorkoutPlayerView(viewModel: workoutPlayerViewModel)
            }
        case .settings:
            NavigationStack {
                SettingsView(settings: settingsManager)
            }
        }
    }
}

/// A wrapper to make AppError Identifiable for .alert(item:)
struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: AppError
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
    let navigationManager = NavigationManager()
    
    ContentView(
        navigationManager: navigationManager,
        devicesViewModel: devicesVM,
        workoutPlayerViewModel: workoutVM,
        workoutManager: manager,
        settingsManager: settings
    )
    .environment(ErrorManager())
}
