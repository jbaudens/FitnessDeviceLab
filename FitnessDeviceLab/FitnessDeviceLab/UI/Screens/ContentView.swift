import SwiftUI

struct ContentView: View {
    @Environment(\.bluetoothProvider) var bluetoothManager
    @Environment(WorkoutSessionManager.self) var workoutManager

    var body: some View {
        TabView {
            // Tab 1: Devices
            NavigationStack {
                DevicesTabView()
            }
            .tabItem {
                Label("Devices", systemImage: "antenna.radiowaves.left.and.right")
            }
            
            // Tab 2: Library
            NavigationStack {
                WorkoutLibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            
            // Tab 3: Workout
            NavigationStack {
                WorkoutPlayerView()
            }
            .tabItem {
                Label("Workout", systemImage: "play.circle")
            }
            
            // Tab 4: Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}
