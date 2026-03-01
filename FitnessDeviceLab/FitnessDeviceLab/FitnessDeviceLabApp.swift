//
//  FitnessDeviceLabApp.swift
//  FitnessDeviceLab
//
//  Created by JB Baudens on 2/27/26.
//

import SwiftUI
import SwiftData

@main
struct FitnessDeviceLabApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject private var workoutManager = WorkoutSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bluetoothManager)
                .environmentObject(workoutManager)
        }
    }
}
